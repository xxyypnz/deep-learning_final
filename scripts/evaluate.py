"""Unified evaluator for the PostgreSQL SQL coverage task.

This file replaces the split Python-side evaluation helpers:

- validate a submission JSON
- extract generated SQL into runnable files
- compute coverage metrics from genhtml/gcov HTML
- write the two leaderboard metrics: PrecNF and efficiency

The PostgreSQL build/run/coverage collection is still delegated to
evaluate_coverage.sh when the `platform` command is used, because that step is
environment-specific and already encoded as shell tooling.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import subprocess
import sys
import textwrap
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
TOOLKIT_DIR = SCRIPT_DIR.parent

DEFAULT_SUBMISSION = TOOLKIT_DIR / "outputs" / "submission.json"
DEFAULT_PARSED_SQL = TOOLKIT_DIR / "outputs" / "parsed_sql"
DEFAULT_MERGED_SQL = TOOLKIT_DIR / "outputs" / "all_gen_sql.sql"
DEFAULT_COVERAGE_DIR = TOOLKIT_DIR / "outputs" / "coverage_workspace"
DEFAULT_RESULT = TOOLKIT_DIR / "outputs" / "eval_result.json"
DEFAULT_SCORES = TOOLKIT_DIR / "outputs" / "scores.txt"

TRIVIAL = re.compile(r"^\s*\{\s*\}$|^\s*\}\s*$|^\s*\}\s*;\s*$|^return\b")
C_TYPES = {
    "int",
    "char",
    "bool",
    "float",
    "double",
    "long",
    "short",
    "void",
    "unsigned",
    "signed",
    "size_t",
    "FILE",
    "va_list",
    "int8",
    "int16",
    "int32",
    "int64",
    "uint8",
    "uint16",
    "uint32",
    "uint64",
    "Oid",
    "Datum",
    "BlockNumber",
    "OffsetNumber",
    "Index",
    "xid",
    "xid8",
    "TransactionId",
    "CommandId",
    "SubTransactionId",
    "PartitionKey",
    "PartitionDesc",
    "Relation",
    "HeapTuple",
    "HeapScanDesc",
    "Snapshot",
    "StringInfo",
    "StringInfoData",
    "List",
    "ListCell",
    "Node",
    "Expr",
    "Plan",
    "PlanState",
    "struct",
    "union",
    "enum",
    "typedef",
}
NON_TYPES = {
    "PG_RETURN",
    "PG_GETARG",
    "PG_ARGISNULL",
    "PG_FREE",
    "PG_MODULE_MAGIC",
    "PG_MAGIC",
    "XLogReadBufferForRedoExtended",
    "ExecInitStoredGenerated",
    "ExecShutdownNode_walker",
    "SetUserIdAndSecContext",
    "GetUserIdAndSecContext",
    "DropErrorMsgWrongType",
}


def default_dataset() -> Path:
    for name in ("test_v3.json", "test_v3(1).json"):
        path = TOOLKIT_DIR / "data" / name
        if path.exists():
            return path
    return TOOLKIT_DIR / "data" / "test_v3.json"


def load_json(path: Path):
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def as_list(data):
    return data if isinstance(data, list) else [data]


def extract_sql_blocks(text: str) -> list[str]:
    return [block.strip() for block in re.findall(r"<sql>(.*?)</sql>", text or "", re.DOTALL | re.IGNORECASE)]


def clean_sql(sql: str) -> str:
    lines = [line.rstrip() for line in sql.splitlines()]
    text = textwrap.dedent("\n".join(lines))
    result = []
    in_copy = False
    for line in text.split("\n"):
        stripped = line.lstrip()
        if re.match(r"COPY\s", stripped, re.IGNORECASE) and "FROM STDIN" in stripped.upper():
            in_copy = True
            result.append(line)
        elif in_copy and stripped == r"\." and line != stripped:
            result.append(stripped)
            in_copy = False
        elif in_copy:
            result.append(stripped)
        else:
            result.append(line)
    return "\n".join(result).strip()


def count_sql_statements(sql: str) -> int:
    """Count top-level SQL statements by semicolon.

    Semicolons inside single/double quotes, line/block comments, and PostgreSQL
    dollar-quoted bodies are ignored. This is used only for the efficiency
    tie-breaker.
    """
    count = 0
    i = 0
    n = len(sql)
    state = "normal"
    dollar_tag = ""

    while i < n:
        ch = sql[i]
        nxt = sql[i + 1] if i + 1 < n else ""

        if state == "normal":
            if ch == "-" and nxt == "-":
                state = "line_comment"
                i += 2
                continue
            if ch == "/" and nxt == "*":
                state = "block_comment"
                i += 2
                continue
            if ch == "'":
                state = "single"
                i += 1
                continue
            if ch == '"':
                state = "double"
                i += 1
                continue
            if ch == "$":
                m = re.match(r"\$[A-Za-z_][A-Za-z_0-9]*\$|\$\$", sql[i:])
                if m:
                    dollar_tag = m.group(0)
                    state = "dollar"
                    i += len(dollar_tag)
                    continue
            if ch == ";":
                count += 1
        elif state == "line_comment":
            if ch in "\r\n":
                state = "normal"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "normal"
                i += 2
                continue
        elif state == "single":
            if ch == "'" and nxt == "'":
                i += 2
                continue
            if ch == "'":
                state = "normal"
        elif state == "double":
            if ch == '"' and nxt == '"':
                i += 2
                continue
            if ch == '"':
                state = "normal"
        elif state == "dollar":
            if sql.startswith(dollar_tag, i):
                state = "normal"
                i += len(dollar_tag)
                continue
        i += 1

    return count


def validate_submission(submission_path: Path, dataset_path: Path, max_sql_cases: int = 0) -> dict:
    errors: list[str] = []
    warnings: list[str] = []

    if not submission_path.exists():
        raise SystemExit(f"submission not found: {submission_path}")
    if not dataset_path.exists():
        raise SystemExit(f"dataset not found: {dataset_path}")

    data = load_json(submission_path)
    dataset = load_json(dataset_path)

    if not isinstance(data, list):
        errors.append("submission root must be a JSON array")
        data = []
    if not isinstance(dataset, list):
        errors.append("dataset root must be a JSON array")
        dataset = []

    dataset_ids = {item.get("id") for item in dataset}
    seen_ids = set()
    total_sql_cases = 0
    empty_records = 0
    sql_statement_count = 0

    for idx, item in enumerate(data):
        if not isinstance(item, dict):
            errors.append(f"item {idx} is not an object")
            continue

        item_id = item.get("id")
        generated = item.get("generated_sql_tests")

        if item_id is None:
            errors.append(f"item {idx} is missing id")
        elif item_id not in dataset_ids:
            warnings.append(f"id={item_id} is not in dataset")
        elif item_id in seen_ids:
            warnings.append(f"id={item_id} appears more than once")
        seen_ids.add(item_id)

        if not isinstance(generated, str):
            errors.append(f"id={item_id} generated_sql_tests must be a string")
            continue

        sql_blocks = extract_sql_blocks(generated)
        total_sql_cases += len(sql_blocks)
        sql_statement_count += sum(count_sql_statements(clean_sql(block)) for block in sql_blocks)

        if "<test_cases" not in generated:
            warnings.append(f"id={item_id} is missing <test_cases>")
        if not sql_blocks:
            empty_records += 1
            warnings.append(f"id={item_id} has no <sql>...</sql> block")

    missing_ids = dataset_ids - seen_ids
    if missing_ids:
        warnings.append(f"submission misses {len(missing_ids)} dataset ids")
    if max_sql_cases > 0 and total_sql_cases > max_sql_cases:
        errors.append(f"SQL case count {total_sql_cases} exceeds max {max_sql_cases}")

    return {
        "records": len(data),
        "dataset_ids": len(dataset_ids),
        "sql_cases": total_sql_cases,
        "sql_statements": sql_statement_count,
        "empty_records": empty_records,
        "warnings": warnings,
        "errors": errors,
    }


def extract_submission_sql(
    input_json: Path,
    output_root: Path,
    merged_sql: Path,
    input_name: str | None = None,
) -> dict:
    data = as_list(load_json(input_json))
    run_name = input_name or input_json.stem
    output_dir = output_root / run_name
    output_dir.mkdir(parents=True, exist_ok=True)
    merged_sql.parent.mkdir(parents=True, exist_ok=True)

    all_sqls: list[tuple[object, str]] = []

    for item in data:
        commit_id = item.get("id", "unknown") if isinstance(item, dict) else "unknown"
        raw_sql_text = item.get("generated_sql_tests", "") if isinstance(item, dict) else ""
        cleaned_blocks = [clean_sql(sql) for sql in extract_sql_blocks(raw_sql_text)]
        if not cleaned_blocks:
            continue

        all_sqls.extend((commit_id, sql) for sql in cleaned_blocks)
        file_path = output_dir / f"test_{commit_id}.sql"
        with file_path.open("w", encoding="utf-8") as f:
            f.write(f"-- ===== Commit {commit_id} =====\n")
            f.write(f"-- Source: {item.get('commit', '')} - {item.get('subject', '')}\n\n")
            for idx, cleaned in enumerate(cleaned_blocks, start=1):
                f.write(f"-- --- Test Case {idx} ---\n")
                f.write(cleaned + "\n\n")

    with merged_sql.open("w", encoding="utf-8") as f:
        f.write("\\pset pager off\n")
        f.write("SET statement_timeout = 5000;\n")
        f.write("SET lock_timeout = 1000;\n")
        f.write("SET idle_in_transaction_session_timeout = 5000;\n\n")
        for idx, (commit_id, sql) in enumerate(all_sqls, start=1):
            f.write(f"-- ===== Test Case {idx} (commit {commit_id}) =====\n")
            f.write(sql + "\n\n")

    return {
        "input_records": len(data),
        "sql_cases": len(all_sqls),
        "sql_statements": sum(count_sql_statements(sql) for _, sql in all_sqls),
        "output_dir": str(output_dir),
        "merged_sql": str(merged_sql),
    }


def is_meaningful(line: str) -> bool:
    return not TRIVIAL.match(line)


def is_comment(line: str) -> bool:
    s = line.strip()
    return s.startswith("*") or s.startswith("/*") or s.startswith("//")


def is_declaration(code: str) -> bool:
    s = code.strip()
    if not s or is_comment(s):
        return False

    first = s.split()[0] if s.split() else ""
    if first in {"if", "for", "while", "switch", "else", "goto", "do", "case", "return", "break", "continue"}:
        return False

    rest = s
    for _ in range(4):
        tok = rest.split()[0] if rest.split() else ""
        if tok in {"static", "const", "extern", "register", "inline", "volatile"}:
            rest = rest[len(tok) :].strip()
        else:
            break

    first = rest.split()[0] if rest.split() else ""
    if not first:
        return False

    type_word = first.rstrip("*")
    is_type = type_word in C_TYPES or (type_word[:1].isupper() and type_word not in NON_TYPES)
    if not is_type:
        return False

    after_type = rest[len(first) :].strip()
    if after_type.startswith("*"):
        after_type = after_type[1:].strip()
    if not after_type or after_type[0] in {"(", "[", ".", "-", "="}:
        return False
    return True


def is_control_only(code: str) -> bool:
    s = code.strip()
    if not s:
        return True
    return bool(
        re.match(r"^\{\s*\}|^\}\s*;?\s*$", s)
        or re.match(r"^(continue|break)\s*;?\s*$", s)
        or re.match(r"^else\s*(?:\{|$)", s)
        or re.match(r"^goto\s+\w+\s*;?\s*$", s)
    )


def count_meaningful_added(patches: list[dict]) -> int:
    total = 0
    for patch in patches:
        for block in patch.get("diff_blocks", []):
            for line in block.get("added", []):
                stripped = line.strip()
                if stripped and is_meaningful(stripped) and not is_comment(stripped) and not is_declaration(stripped):
                    total += 1
    return total


def collect_matched_lines(match_info: dict) -> list[dict]:
    lines = []
    seen = set()
    for patch in match_info.get("patches", []):
        file_path = patch.get("file", "")
        for block in patch.get("blocks", []):
            if not block.get("matched", False):
                continue
            for line_info in block.get("lines", []):
                code = line_info["code"]
                key = (file_path, line_info["source_line"])
                if key in seen or is_comment(code) or is_declaration(code):
                    continue
                seen.add(key)
                lines.append({"file": file_path, "line_no": line_info["source_line"], "code": code})
    return lines


def find_gcov_path(file_path: str, coverage_dir: Path) -> Path | None:
    rel = file_path.replace("\\", "/")
    candidates = [coverage_dir / "report" / f"{rel}.gcov.html"]
    if rel.startswith("src/"):
        no_src = rel[4:]
        candidates.append(coverage_dir / "report" / f"{no_src}.gcov.html")
        if no_src.startswith("backend/"):
            candidates.append(coverage_dir / "report" / f"{no_src[8:]}.gcov.html")
    for path in candidates:
        if path.exists():
            return path
    return None


def parse_gcov(html_path: Path) -> dict[int, dict]:
    if not html_path.exists():
        return {}
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    result: dict[int, dict] = {}

    for raw_line in text.splitlines():
        match = re.search(r'<span\s+id="L(\d+)"', raw_line)
        if not match:
            continue
        line_no = int(match.group(1))
        rendered = html.unescape(re.sub(r"<[^>]+>", "", raw_line))
        rendered = re.sub(rf"^\s*{line_no}\s*", "", rendered, count=1)
        count = 0
        gcov_code = ""
        cov_match = re.match(r"^\s*(\d+|#####|-)\s*:\s?(.*)", rendered)
        if cov_match:
            if cov_match.group(1).isdigit():
                count = int(cov_match.group(1))
            gcov_code = cov_match.group(2)
        else:
            no_count_match = re.match(r"^\s*:\s?(.*)", rendered)
            if no_count_match:
                gcov_code = no_count_match.group(1)
        result[line_no] = {"count": count, "gcov_code": gcov_code}

    if result:
        return result

    try:
        from bs4 import BeautifulSoup
    except ImportError as exc:
        raise RuntimeError("Missing dependency beautifulsoup4. Install requirements.txt first.") from exc

    soup = BeautifulSoup(text, "html.parser")
    for a_tag in soup.find_all("a"):
        span_line = a_tag.find("span", class_="lineNum")
        if not span_line:
            continue
        try:
            line_no = int(span_line.text.strip())
        except ValueError:
            continue
        cov_span = a_tag.find("span", class_=re.compile("lineCov|lineNoCov|lineDead"))
        if not cov_span:
            continue
        match = re.match(r"^\s*(\d+|#####)\s*:\s*(.*)", cov_span.text.strip())
        count = 0
        gcov_code = ""
        if match:
            if match.group(1) != "#####":
                count = int(match.group(1))
            gcov_code = match.group(2)
        result[line_no] = {"count": count, "gcov_code": gcov_code}
    return result


def find_gcov_match(gcov_data: dict[int, dict], target_line: int, target_code: str, window: int = 1):
    target_clean = target_code.strip()
    gcov_info = gcov_data.get(target_line)
    if gcov_info and gcov_info["gcov_code"].strip() == target_clean:
        return target_line, gcov_info["count"], gcov_info["gcov_code"], "exact"

    lo = max(1, target_line - window)
    hi = min(max(gcov_data.keys()) + 1 if gcov_data else target_line + window + 1, target_line + window + 1)
    best_fuzzy = None
    for line_no in range(lo, hi):
        info = gcov_data.get(line_no)
        if not info:
            continue
        gcov_clean = info["gcov_code"].strip()
        if gcov_clean == target_clean:
            return line_no, info["count"], info["gcov_code"], "fuzzy" if line_no != target_line else "exact"
        if best_fuzzy is None and target_clean and (target_clean in gcov_clean or gcov_clean in target_clean):
            best_fuzzy = (line_no, info["count"], info["gcov_code"], "fuzzy")
    if best_fuzzy:
        return best_fuzzy
    if gcov_info:
        return target_line, gcov_info["count"], gcov_info["gcov_code"], "line_only"
    return None, None, None, "not_found"


def evaluate_metrics(json_path: Path, coverage_dir: Path) -> dict:
    data = as_list(load_json(json_path))
    results = {}
    global_total_added = 0
    global_matched = 0
    global_covered = 0
    global_not_found = 0
    gcov_cache: dict[Path, dict[int, dict]] = {}

    for item in data:
        item_id = item.get("id", "unknown")
        total_added = count_meaningful_added(item.get("patches", []))
        matched_lines = collect_matched_lines(item.get("match_info", {}))

        covered = 0
        not_found = 0
        line_details = []

        for ml in matched_lines:
            html_path = find_gcov_path(ml["file"], coverage_dir)
            if html_path is None:
                not_found += 1
                line_details.append(
                    {
                        "file": ml["file"],
                        "line_no": ml["line_no"],
                        "gcov_line_no": None,
                        "code": ml["code"],
                        "gcov_code": None,
                        "gcov_count": None,
                        "covered": False,
                        "match_type": "gcov_not_found",
                    }
                )
                continue

            if html_path not in gcov_cache:
                gcov_cache[html_path] = parse_gcov(html_path)
            gcov_line_no, count, gcov_code, match_type = find_gcov_match(
                gcov_cache[html_path], ml["line_no"], ml["code"]
            )
            is_covered = count is not None and count > 0
            covered += int(is_covered)
            not_found += int(gcov_line_no is None)
            line_details.append(
                {
                    "file": ml["file"],
                    "line_no": ml["line_no"],
                    "gcov_line_no": gcov_line_no,
                    "code": ml["code"],
                    "gcov_code": gcov_code or "",
                    "gcov_count": count,
                    "covered": is_covered,
                    "match_type": match_type or "not_found",
                }
            )

        total_matched = len(matched_lines)
        exec_lines = [ld for ld in line_details if not is_control_only(ld["code"])]
        exec_matched = len(exec_lines)
        exec_covered = sum(1 for ld in exec_lines if ld["covered"])

        results[str(item_id)] = {
            "subject": item.get("subject", ""),
            "total_added": total_added,
            "total_matched": total_matched,
            "not_found": not_found,
            "covered": covered,
            "recall": round(total_matched / total_added, 4) if total_added else 0.0,
            "precision": round(covered / total_matched, 4) if total_matched else 0.0,
            "precision_excl_ctrl": round(exec_covered / exec_matched, 4) if exec_matched else 0.0,
            "precision_excl_not_found": round(covered / (total_matched - not_found), 4)
            if total_matched - not_found > 0
            else 0.0,
            "line_details": line_details,
        }

        global_total_added += total_added
        global_matched += total_matched
        global_covered += covered
        global_not_found += not_found

    all_exec_lines = [ld for r in results.values() for ld in r["line_details"] if not is_control_only(ld["code"])]
    all_exec_covered = sum(1 for ld in all_exec_lines if ld["covered"])
    summary = {
        "n_items": len(data),
        "total_meaningful_added": global_total_added,
        "total_matched": global_matched,
        "total_not_found": global_not_found,
        "total_covered": global_covered,
        "global_recall": round(global_matched / global_total_added, 4) if global_total_added else 0.0,
        "global_precision": round(global_covered / global_matched, 4) if global_matched else 0.0,
        "global_precision_excl_ctrl": round(all_exec_covered / len(all_exec_lines), 4) if all_exec_lines else 0.0,
        "global_precision_excl_not_found": round(global_covered / (global_matched - global_not_found), 4)
        if global_matched - global_not_found > 0
        else 0.0,
    }
    return {"results": results, "summary": summary}


def compute_efficiency(sql_count: int, prec_nf: float) -> float:
    if prec_nf <= 0:
        return 999999.0
    return (max(sql_count, 1) ** 0.35) / (prec_nf * 100)


def write_scores(scores_path: Path, prec_nf: float, efficiency: float) -> None:
    scores_path.parent.mkdir(parents=True, exist_ok=True)
    scores_path.write_text(f"PrecNF: {prec_nf:.6f}\nefficiency: {efficiency:.6f}\n", encoding="utf-8")


def find_submission(input_dir: Path) -> Path | None:
    res_dir = input_dir / "res"
    if not res_dir.exists():
        return None
    preferred = res_dir / "submission.json"
    if preferred.exists():
        return preferred
    candidates = sorted(res_dir.glob("*.json"))
    return candidates[0] if candidates else None


def cmd_check(args) -> int:
    stats = validate_submission(Path(args.submission), Path(args.dataset), args.max_sql_cases)
    print(json.dumps({k: v for k, v in stats.items() if k not in {"warnings", "errors"}}, indent=2, ensure_ascii=False))
    if stats["warnings"]:
        print("\nWarnings:")
        for warning in stats["warnings"][:50]:
            print(f"- {warning}")
    if stats["errors"]:
        print("\nErrors:", file=sys.stderr)
        for error in stats["errors"]:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("\nOK")
    return 0


def cmd_extract(args) -> int:
    stats = extract_submission_sql(Path(args.input), Path(args.output_root), Path(args.merged_sql), args.input_name)
    print(json.dumps(stats, indent=2, ensure_ascii=False))
    return 0


def cmd_metrics(args) -> int:
    eval_data = evaluate_metrics(Path(args.dataset), Path(args.coverage_dir))
    result_path = Path(args.result)
    result_path.parent.mkdir(parents=True, exist_ok=True)
    result_path.write_text(json.dumps(eval_data, indent=2, ensure_ascii=False), encoding="utf-8")

    sql_count = args.sql_count
    if args.sql:
        sql_count = count_sql_statements(Path(args.sql).read_text(encoding="utf-8"))
    prec_nf = float(eval_data["summary"].get("global_precision_excl_not_found", 0.0))
    efficiency = compute_efficiency(sql_count or 0, prec_nf)
    if args.scores:
        write_scores(Path(args.scores), prec_nf, efficiency)

    print(f"PrecNF: {prec_nf:.6f}")
    print(f"efficiency: {efficiency:.6f}")
    print(f"result: {result_path}")
    return 0


def cmd_platform(args) -> int:
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    dataset = Path(args.dataset) if args.dataset else input_dir / "ref" / "test_v3.json"
    if not dataset.exists():
        dataset = default_dataset()

    submission = Path(args.submission) if args.submission else find_submission(input_dir)
    if submission is None or not submission.exists():
        write_scores(output_dir / "scores.txt", 0.0, 999999.0)
        raise SystemExit(f"submission not found under {input_dir / 'res'}")

    validation = validate_submission(submission, dataset, args.max_sql_cases)
    if validation["errors"]:
        write_scores(output_dir / "scores.txt", 0.0, 999999.0)
        (output_dir / "validation.json").write_text(json.dumps(validation, indent=2, ensure_ascii=False), encoding="utf-8")
        return 1

    sql_file = output_dir / "all_gen_sql.sql"
    extract_stats = extract_submission_sql(submission, output_dir / "parsed_sql", sql_file, submission.stem)

    coverage_script = SCRIPT_DIR / "evaluate_coverage.sh"
    workspace = output_dir / "evaluation_workspace"
    result = output_dir / "eval_result.json"
    cmd = [
        "bash",
        str(coverage_script),
        "--sql",
        str(sql_file),
        "--dataset",
        str(dataset),
        "--eval-output",
        str(result),
        "--workspace",
        str(workspace),
        "--eval-script",
        str(Path(__file__).resolve()),
    ]
    if args.skip_build:
        cmd.append("--skip-build")
    if args.pg_source:
        cmd.extend(["--pg-source", args.pg_source])
    if args.port:
        cmd.extend(["--port", str(args.port)])
    if not args.with_branch:
        cmd.append("--no-branch-coverage")

    log_path = output_dir / "evaluation.log"
    try:
        with log_path.open("w", encoding="utf-8") as log:
            subprocess.run(cmd, check=True, stdout=log, stderr=subprocess.STDOUT)
    except Exception as exc:
        write_scores(output_dir / "scores.txt", 0.0, 999999.0)
        with log_path.open("a", encoding="utf-8") as log:
            log.write(f"\n[ERROR] {exc}\n")
        return 1

    if not result.exists():
        write_scores(output_dir / "scores.txt", 0.0, 999999.0)
        return 1

    eval_data = load_json(result)
    prec_nf = float(eval_data.get("summary", {}).get("global_precision_excl_not_found", 0.0))
    sql_count = int(extract_stats.get("sql_statements", 0))
    efficiency = compute_efficiency(sql_count, prec_nf)
    write_scores(output_dir / "scores.txt", prec_nf, efficiency)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Unified evaluator for submission checking, SQL extraction, and metrics.")
    sub = parser.add_subparsers(dest="command")

    p = sub.add_parser("check", help="validate submission JSON")
    p.add_argument("submission", nargs="?", default=str(DEFAULT_SUBMISSION))
    p.add_argument("--dataset", default=str(default_dataset()))
    p.add_argument("--max-sql-cases", type=int, default=0)
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("extract", help="extract <sql> blocks from submission")
    p.add_argument("-i", "--input", default=str(DEFAULT_SUBMISSION))
    p.add_argument("--input-name", default=None)
    p.add_argument("-o", "--output-root", default=str(DEFAULT_PARSED_SQL))
    p.add_argument("-m", "--merged-sql", default=str(DEFAULT_MERGED_SQL))
    p.set_defaults(func=cmd_extract)

    p = sub.add_parser("metrics", help="compute coverage metrics from genhtml report")
    p.add_argument("dataset", nargs="?", default=str(default_dataset()))
    p.add_argument("coverage_dir", nargs="?", default=str(DEFAULT_COVERAGE_DIR))
    p.add_argument("result", nargs="?", default=str(DEFAULT_RESULT))
    p.add_argument("--sql", default=None, help="merged SQL file used to count efficiency")
    p.add_argument("--sql-count", type=int, default=0)
    p.add_argument("--scores", default=str(DEFAULT_SCORES))
    p.set_defaults(func=cmd_metrics)

    p = sub.add_parser("platform", help="platform-style end-to-end evaluation")
    p.add_argument("input_dir")
    p.add_argument("output_dir")
    p.add_argument("--submission", default=None)
    p.add_argument("--dataset", default=None)
    p.add_argument("--max-sql-cases", type=int, default=0)
    p.add_argument("--skip-build", action="store_true")
    p.add_argument("--pg-source", default=None)
    p.add_argument("--port", default=None)
    p.add_argument("--with-branch", action="store_true")
    p.set_defaults(func=cmd_platform)

    return parser


def main(argv: list[str] | None = None) -> int:
    raw = argv if argv is not None else sys.argv[1:]
    commands = {"check", "extract", "metrics", "platform", "-h", "--help"}
    if not raw or raw[0] not in commands:
        # Backward compatibility with the old metrics script:
        # python evaluate.py dataset coverage_dir result_path
        if len(raw) <= 3:
            return cmd_metrics(
                argparse.Namespace(
                    dataset=raw[0] if len(raw) > 0 else str(default_dataset()),
                    coverage_dir=raw[1] if len(raw) > 1 else str(DEFAULT_COVERAGE_DIR),
                    result=raw[2] if len(raw) > 2 else str(DEFAULT_RESULT),
                    sql=None,
                    sql_count=0,
                    scores=None,
                )
            )

    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
