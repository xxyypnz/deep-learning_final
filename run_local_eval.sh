#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    cat <<EOF
Usage:
  $0 --submission PATH [options]
  $0 --sql PATH [options]

Options:
  --submission PATH   提交 JSON，包含 id 和 generated_sql_tests
  --sql PATH          已经合并好的 SQL 文件，例如 outputs/all_gen_sql.sql
  --dataset PATH      测试集 JSON，默认自动使用 test_v3.json 或 test_v3(1).json
  --name NAME         本次评测名称，默认从输入文件名推断
  --skip-build        复用已编译的 PostgreSQL
  --pg-source PATH    PostgreSQL 源码目录
  --port PORT         PostgreSQL 测试端口，默认 55432
  --with-branch       启用分支覆盖率；本地 macOS 不推荐
  --min-score VALUE   若 global_precision_excl_not_found 低于该值，则退出码为 2
  -h, --help          显示帮助

Outputs:
  outputs/local_eval/<name>/all_gen_sql.sql
  outputs/local_eval/<name>/coverage_workspace/
  outputs/local_eval/<name>/eval_result.json
  outputs/local_eval/<name>/summary.txt
EOF
}

abs_path() {
    case "$1" in
        /*) printf "%s\n" "$1" ;;
        *) printf "%s/%s\n" "$SCRIPT_DIR" "$1" ;;
    esac
}

default_dataset() {
    if [ -f "$SCRIPT_DIR/data/test_v3.json" ]; then
        printf "%s\n" "$SCRIPT_DIR/data/test_v3.json"
    else
        printf "%s\n" "$SCRIPT_DIR/data/test_v3(1).json"
    fi
}

INPUT_SUBMISSION=""
INPUT_SQL=""
DATASET="$(default_dataset)"
RUN_NAME=""
SKIP_BUILD=false
NO_BRANCH=true
MIN_SCORE=""
PG_SOURCE=""
PORT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --submission) INPUT_SUBMISSION="$2"; shift 2 ;;
        --sql) INPUT_SQL="$2"; shift 2 ;;
        --dataset) DATASET="$2"; shift 2 ;;
        --name) RUN_NAME="$2"; shift 2 ;;
        --skip-build) SKIP_BUILD=true; shift ;;
        --pg-source) PG_SOURCE="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --with-branch) NO_BRANCH=false; shift ;;
        --min-score) MIN_SCORE="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "[ERROR] 未知参数: $1" >&2; usage; exit 1 ;;
    esac
done

if [ -n "$INPUT_SUBMISSION" ] && [ -n "$INPUT_SQL" ]; then
    echo "[ERROR] --submission 和 --sql 二选一，不能同时指定。" >&2
    exit 1
fi

if [ -z "$INPUT_SUBMISSION" ] && [ -z "$INPUT_SQL" ]; then
    echo "[ERROR] 请指定 --submission PATH 或 --sql PATH。" >&2
    usage
    exit 1
fi

DATASET="$(abs_path "$DATASET")"
if [ ! -f "$DATASET" ]; then
    echo "[ERROR] 数据集不存在: $DATASET" >&2
    exit 1
fi

if [ -n "$INPUT_SUBMISSION" ]; then
    INPUT_SUBMISSION="$(abs_path "$INPUT_SUBMISSION")"
    if [ ! -f "$INPUT_SUBMISSION" ]; then
        echo "[ERROR] submission 不存在: $INPUT_SUBMISSION" >&2
        exit 1
    fi
    if [ -z "$RUN_NAME" ]; then
        RUN_NAME="$(basename "$INPUT_SUBMISSION")"
        RUN_NAME="${RUN_NAME%.*}"
    fi
else
    INPUT_SQL="$(abs_path "$INPUT_SQL")"
    if [ ! -f "$INPUT_SQL" ]; then
        echo "[ERROR] SQL 文件不存在: $INPUT_SQL" >&2
        exit 1
    fi
    if [ -z "$RUN_NAME" ]; then
        RUN_NAME="$(basename "$INPUT_SQL")"
        RUN_NAME="${RUN_NAME%.*}"
    fi
fi

RUN_NAME="$(printf "%s" "$RUN_NAME" | tr -c 'A-Za-z0-9._-' '_')"
RUN_DIR="$SCRIPT_DIR/outputs/local_eval/$RUN_NAME"
SQL_FILE="$RUN_DIR/all_gen_sql.sql"
WORKSPACE="$RUN_DIR/coverage_workspace"
RESULT="$RUN_DIR/eval_result.json"
SUMMARY="$RUN_DIR/summary.txt"

mkdir -p "$RUN_DIR"

if [ -n "$INPUT_SUBMISSION" ]; then
    echo "[INFO] 从 submission 提取 SQL: $INPUT_SUBMISSION"
    python3 "$SCRIPT_DIR/scripts/evaluate.py" extract \
        -i "$INPUT_SUBMISSION" \
        -o "$RUN_DIR/parsed_sql" \
        -m "$SQL_FILE"
else
    SQL_FILE="$INPUT_SQL"
    echo "[INFO] 直接使用 SQL 文件: $SQL_FILE"
fi

EVAL_ARGS=(
    "$SCRIPT_DIR/scripts/evaluate_coverage.sh"
    --sql "$SQL_FILE"
    --dataset "$DATASET"
    --eval-output "$RESULT"
    --workspace "$WORKSPACE"
    --eval-script "$SCRIPT_DIR/scripts/evaluate.py"
)

if [ "$SKIP_BUILD" = true ]; then
    EVAL_ARGS+=(--skip-build)
fi

if [ -n "$PG_SOURCE" ]; then
    EVAL_ARGS+=(--pg-source "$(abs_path "$PG_SOURCE")")
fi

if [ -n "$PORT" ]; then
    EVAL_ARGS+=(--port "$PORT")
fi

if [ "$NO_BRANCH" = true ]; then
    EVAL_ARGS+=(--no-branch-coverage)
fi

echo "[INFO] 开始本地评测: $RUN_NAME"
"${EVAL_ARGS[@]}"

if [ ! -f "$RESULT" ]; then
    echo "[ERROR] 评测未生成结果文件: $RESULT" >&2
    echo "[INFO] 请查看日志: $WORKSPACE/run.log" >&2
    exit 1
fi

python3 - "$RESULT" "$SUMMARY" "$MIN_SCORE" <<'PY'
import json
import sys
from pathlib import Path

result_path = Path(sys.argv[1])
summary_path = Path(sys.argv[2])
min_score_raw = sys.argv[3]

with result_path.open(encoding="utf-8") as f:
    data = json.load(f)

summary = data.get("summary", {})
score = float(summary.get("global_precision_excl_not_found", 0.0))

lines = [
    "Local evaluation summary",
    f"result_file: {result_path}",
    f"n_items: {summary.get('n_items')}",
    f"total_meaningful_added: {summary.get('total_meaningful_added')}",
    f"total_matched: {summary.get('total_matched')}",
    f"total_not_found: {summary.get('total_not_found')}",
    f"total_covered: {summary.get('total_covered')}",
    f"global_recall: {summary.get('global_recall')}",
    f"global_precision: {summary.get('global_precision')}",
    f"global_precision_excl_ctrl: {summary.get('global_precision_excl_ctrl')}",
    f"global_precision_excl_not_found: {score}",
]

text = "\n".join(lines) + "\n"
summary_path.write_text(text, encoding="utf-8")
print(text)

if min_score_raw:
    min_score = float(min_score_raw)
    if score < min_score:
        print(
            f"[FAIL] global_precision_excl_not_found={score} < min_score={min_score}",
            file=sys.stderr,
        )
        sys.exit(2)
PY

echo "[INFO] 覆盖率 HTML: $WORKSPACE/report/index.html"
echo "[INFO] SQL 输出日志: $WORKSPACE/psql_output.log"
echo "[INFO] 运行日志: $WORKSPACE/run.log"
