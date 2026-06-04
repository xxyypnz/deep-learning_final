#!/usr/bin/env python3
"""Retrieve simple lexical few-shot examples from train.json for test commits."""

from __future__ import annotations

import argparse
import json
import math
import re
from collections import Counter
from pathlib import Path


TOKEN_RE = re.compile(r"[A-Za-z_][A-Za-z_0-9]+")


def tokens(record: dict) -> Counter[str]:
    parts = [record.get("subject", ""), record.get("email_body", "")]
    for patch in record.get("patches", []):
        parts.extend(
            [
                patch.get("file", ""),
                patch.get("function", ""),
                patch.get("raw_diff", ""),
            ]
        )
    toks = [tok.lower() for tok in TOKEN_RE.findall("\n".join(parts))]
    stop = {
        "the",
        "and",
        "for",
        "with",
        "that",
        "this",
        "from",
        "postgresql",
        "pgsql",
        "commit",
        "diff",
    }
    return Counter(tok for tok in toks if len(tok) > 2 and tok not in stop)


def cosine(a: Counter[str], b: Counter[str]) -> float:
    shared = set(a) & set(b)
    dot = sum(a[t] * b[t] for t in shared)
    na = math.sqrt(sum(v * v for v in a.values()))
    nb = math.sqrt(sum(v * v for v in b.values()))
    return dot / (na * nb) if na and nb else 0.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", default="data/test_v3.json")
    parser.add_argument("--train", default="data/train.json")
    parser.add_argument("--analysis", default=None, help="Optional analyze_eval.py output")
    parser.add_argument("--ids", default="", help="Comma-separated test ids; default uses analysis order or all")
    parser.add_argument("--top-k", type=int, default=5)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    test = json.loads(Path(args.dataset).read_text(encoding="utf-8"))
    train = json.loads(Path(args.train).read_text(encoding="utf-8"))
    test_by_id = {int(item["id"]): item for item in test}

    if args.ids:
        ids = [int(x) for x in args.ids.split(",") if x.strip()]
    elif args.analysis:
        analysis = json.loads(Path(args.analysis).read_text(encoding="utf-8"))
        ids = [int(row["id"]) for row in analysis.get("commits", []) if row.get("uncovered_count", 0) > 0]
    else:
        ids = sorted(test_by_id)

    train_vecs = [(item, tokens(item)) for item in train]
    results = {}
    for cid in ids:
        query = tokens(test_by_id[cid])
        scored = []
        for item, vec in train_vecs:
            score = cosine(query, vec)
            if score > 0:
                scored.append(
                    {
                        "id": item["id"],
                        "subject": item.get("subject", ""),
                        "score": round(score, 4),
                        "generated_sql_tests": item.get("generated_sql_tests", ""),
                    }
                )
        results[str(cid)] = sorted(scored, key=lambda row: (-row["score"], row["id"]))[: args.top_k]

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

    for cid in ids[:20]:
        print(f"id={cid}")
        for row in results.get(str(cid), [])[:3]:
            print(f"  train={row['id']} score={row['score']:.4f} {row['subject'][:90]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
