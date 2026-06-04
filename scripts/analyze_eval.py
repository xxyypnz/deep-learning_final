#!/usr/bin/env python3
"""Summarize per-commit coverage gaps from eval_result.json."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval", required=True, help="Path to eval_result.json")
    parser.add_argument("--output", required=True, help="Output JSON path")
    parser.add_argument("--top", type=int, default=0, help="Also print top N gaps")
    args = parser.parse_args()

    data = json.loads(Path(args.eval).read_text(encoding="utf-8"))
    rows = []
    for raw_id, result in data.get("results", {}).items():
        denom = int(result.get("total_matched", 0)) - int(result.get("not_found", 0))
        covered = int(result.get("covered", 0))
        uncovered = []
        for line in result.get("line_details", []):
            if not line.get("covered") and line.get("match_type") != "gcov_not_found":
                uncovered.append(
                    {
                        "file": line.get("file"),
                        "line_no": line.get("line_no"),
                        "code": line.get("code"),
                        "match_type": line.get("match_type"),
                    }
                )
        rows.append(
            {
                "id": int(raw_id),
                "subject": result.get("subject", ""),
                "covered": covered,
                "denominator": denom,
                "uncovered_count": max(denom - covered, 0),
                "precision_excl_not_found": result.get("precision_excl_not_found", 0.0),
                "uncovered_lines": uncovered,
            }
        )

    rows.sort(key=lambda row: (-row["uncovered_count"], row["id"]))
    output = {"summary": data.get("summary", {}), "commits": rows}
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.top:
        for row in rows[: args.top]:
            print(
                f"id={row['id']} uncovered={row['uncovered_count']} "
                f"covered={row['covered']}/{row['denominator']} "
                f"pnf={row['precision_excl_not_found']:.4f} {row['subject']}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
