#!/bin/bash
set -e
if [ "${DEBUG:-0}" = "1" ]; then
    set -x
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -d "${TOOLKIT_DIR}/postgresql-13.23" ]; then
    DEFAULT_PG_SOURCE_DIR="${TOOLKIT_DIR}/postgresql-13.23"
elif [ -f "${TOOLKIT_DIR}/postgresql-13.23.tar.bz2" ]; then
    DEFAULT_PG_SOURCE_DIR="${TOOLKIT_DIR}/postgresql-13.23"
else
    DEFAULT_PG_SOURCE_DIR="${TOOLKIT_DIR}/../postgresql-13.23"
fi

# ================= 配置区域 =================
PG_SOURCE_DIR="${PG_SOURCE_DIR:-${DEFAULT_PG_SOURCE_DIR}}"
PG_INSTALL_DIR="${PG_INSTALL_DIR:-${PG_SOURCE_DIR}/install_coverage}"
WORKSPACE_DIR="${WORKSPACE_DIR:-${TOOLKIT_DIR}/outputs/coverage_workspace}"
REPORT_DIR="${WORKSPACE_DIR}/report"
CUSTOM_SQL_FILE="${CUSTOM_SQL_FILE:-${TOOLKIT_DIR}/outputs/all_gen_sql.sql}"
# ---- 持久化日志保存 ----
LOG_SAVE_DIR_WAS_SET=0
if [ -n "${LOG_SAVE_DIR:-}" ]; then
    LOG_SAVE_DIR_WAS_SET=1
fi
LOG_SAVE_DIR="${LOG_SAVE_DIR:-${WORKSPACE_DIR}/logs}"
PORT="${PORT:-55432}"
SOCKET_DIR="${SOCKET_DIR:-/tmp/pgcov-${PORT}}"
# ---- Recall 评测相关配置 ----
if [ -f "${TOOLKIT_DIR}/data/test_v3.json" ]; then
    JSON_DATASET_FILE="${JSON_DATASET_FILE:-${TOOLKIT_DIR}/data/test_v3.json}"
else
    JSON_DATASET_FILE="${JSON_DATASET_FILE:-${TOOLKIT_DIR}/data/test_v3(1).json}"
fi
EVAL_RESULT_PATH="${EVAL_RESULT_PATH:-${TOOLKIT_DIR}/outputs/eval_result.json}"
EVAL_SCRIPT="${EVAL_SCRIPT:-${SCRIPT_DIR}/evaluate.py}"
# ---- v5: Branch Coverage ----
ENABLE_BRANCH_COVERAGE="${ENABLE_BRANCH_COVERAGE:-1}"
LCOV_IGNORE_ERRORS="${LCOV_IGNORE_ERRORS:-gcov,unsupported,inconsistent,range}"

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --skip-build              复用已编译的 PostgreSQL
  --pg-source PATH          PostgreSQL 源码目录，默认 toolkit/postgresql-13.23 或 ../postgresql-13.23
  --pg-install PATH         PostgreSQL coverage 安装目录
  --workspace PATH          coverage 工作目录，默认 outputs/coverage_workspace
  --socket-dir PATH         PostgreSQL Unix socket 目录，默认 /tmp/pgcov-PORT
  --sql PATH                要执行的合并 SQL 文件，默认 outputs/all_gen_sql.sql
  --dataset PATH            原始测试集 JSON
  --eval-output PATH        Recall/Precision 结果 JSON
  --eval-script PATH        评测脚本路径
  --port PORT               PostgreSQL 端口，默认 55432
  --no-branch-coverage      不采集分支覆盖率
  -h, --help                显示帮助
EOF
}

save_log() {
    if [ -z "${LOG_FILE:-}" ] || [ ! -f "$LOG_FILE" ]; then
        return
    fi
    mkdir -p "$LOG_SAVE_DIR"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    cp "$LOG_FILE" "${LOG_SAVE_DIR}/run_${TIMESTAMP}.log"
    echo "[INFO] 日志已保存: ${LOG_SAVE_DIR}/run_${TIMESTAMP}.log"
}
trap save_log EXIT

log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
err()  { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        err "缺少命令: $1"
        exit 1
    fi
}
abs_path() {
    case "$1" in
        /*) printf "%s\n" "$1" ;;
        *) printf "%s/%s\n" "$(pwd)" "$1" ;;
    esac
}

# ================= 参数解析 =================
SKIP_BUILD=false
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-build) SKIP_BUILD=true; shift ;;
        --pg-source) PG_SOURCE_DIR="$2"; shift 2 ;;
        --pg-install) PG_INSTALL_DIR="$2"; shift 2 ;;
        --workspace)
            WORKSPACE_DIR="$2"
            REPORT_DIR="${WORKSPACE_DIR}/report"
            if [ "$LOG_SAVE_DIR_WAS_SET" = "0" ]; then
                LOG_SAVE_DIR="${WORKSPACE_DIR}/logs"
            fi
            shift 2
            ;;
        --socket-dir) SOCKET_DIR="$2"; shift 2 ;;
        --sql) CUSTOM_SQL_FILE="$2"; shift 2 ;;
        --dataset) JSON_DATASET_FILE="$2"; shift 2 ;;
        --eval-output) EVAL_RESULT_PATH="$2"; shift 2 ;;
        --eval-script) EVAL_SCRIPT="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --no-branch-coverage) ENABLE_BRANCH_COVERAGE=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *) err "未知参数: $1"; usage; exit 1 ;;
    esac
done

PG_SOURCE_DIR="$(abs_path "$PG_SOURCE_DIR")"
PG_INSTALL_DIR="$(abs_path "$PG_INSTALL_DIR")"
WORKSPACE_DIR="$(abs_path "$WORKSPACE_DIR")"
REPORT_DIR="${WORKSPACE_DIR}/report"
CUSTOM_SQL_FILE="$(abs_path "$CUSTOM_SQL_FILE")"
JSON_DATASET_FILE="$(abs_path "$JSON_DATASET_FILE")"
EVAL_RESULT_PATH="$(abs_path "$EVAL_RESULT_PATH")"
EVAL_SCRIPT="$(abs_path "$EVAL_SCRIPT")"
LOG_SAVE_DIR="$(abs_path "$LOG_SAVE_DIR")"

if [ ! -d "$PG_SOURCE_DIR" ] && [ -f "${TOOLKIT_DIR}/postgresql-13.23.tar.bz2" ] && [ "$PG_SOURCE_DIR" = "${TOOLKIT_DIR}/postgresql-13.23" ]; then
    log "PostgreSQL 源码目录不存在，正在从 postgresql-13.23.tar.bz2 解压..."
    tar -xjf "${TOOLKIT_DIR}/postgresql-13.23.tar.bz2" -C "$TOOLKIT_DIR"
fi

if [ ! -d "$PG_SOURCE_DIR" ]; then
    err "PostgreSQL 源码目录不存在: $PG_SOURCE_DIR"
    exit 1
fi

if [ ! -f "$CUSTOM_SQL_FILE" ]; then
    err "SQL 文件不存在: $CUSTOM_SQL_FILE。请先运行 scripts/evaluate.py extract 生成 outputs/all_gen_sql.sql"
    exit 1
fi

if [ ! -f "$EVAL_SCRIPT" ]; then
    err "评测脚本不存在: $EVAL_SCRIPT"
    exit 1
fi

require_command awk
require_command bc
require_command lcov
require_command genhtml

if [ "$SKIP_BUILD" = true ] && [ ! -x "$PG_INSTALL_DIR/bin/postgres" ]; then
    err "--skip-build 要求已存在可执行文件: $PG_INSTALL_DIR/bin/postgres"
    exit 1
fi

# ================= Step 0: 清理 =================
log "=== Step 0: 清理环境 ==="

log "删除旧 gcda（不要删 gcno！）"
find "$PG_SOURCE_DIR" -name "*.gcda" -delete

rm -rf "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR" "$REPORT_DIR"

LOG_FILE="${WORKSPACE_DIR}/run.log"
echo "[INFO] 详细日志写入: $LOG_FILE"
if [ "${STREAM_LOG:-0}" = "1" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
else
    exec >> "$LOG_FILE" 2>&1
fi

if [ "$SKIP_BUILD" = false ]; then
    find "$PG_SOURCE_DIR" -name "*.gcno" -delete
    rm -rf "$PG_INSTALL_DIR"
fi

# ================= Step 1: 编译 =================
log "=== Step 1: 全量编译 PostgreSQL (coverage) ==="

cd "$PG_SOURCE_DIR"

if [ "$SKIP_BUILD" = false ]; then
    find "$PG_SOURCE_DIR" -name "*.gcno" -delete
    make clean || true

    ./configure --enable-coverage --prefix="$PG_INSTALL_DIR"
    if ! make -j4; then
        err "编译失败，退出"
        exit 1
    fi
    if ! make install; then
        err "make install 失败，退出"
        exit 1
    fi
    log "编译完成"
else
    log "跳过编译 (--skip-build)"
fi

# ================= Step 2: 环境变量 =================
log "=== Step 2: 设置环境变量 ==="

export PATH="$PG_INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$PG_INSTALL_DIR/lib:$LD_LIBRARY_PATH"

echo "postgres path: $(which postgres)"
echo "psql path: $(which psql)"

# ================= Step 3: 初始化数据库 =================
log "=== Step 3: 初始化数据库 ==="

MY_TEST_DATA="${WORKSPACE_DIR}/data"
initdb -D "$MY_TEST_DATA"

# ================= Step 4: 启动 postgres =================
log "=== Step 4: 启动 PostgreSQL ==="

mkdir -p "$SOCKET_DIR"
chmod 700 "$SOCKET_DIR"
rm -f "$SOCKET_DIR/.s.PGSQL.$PORT" "$SOCKET_DIR/.s.PGSQL.$PORT.lock"

"$PG_INSTALL_DIR/bin/pg_ctl" \
    -D "$MY_TEST_DATA" \
    -l "$WORKSPACE_DIR/server.log" \
    -o "-k $SOCKET_DIR -p $PORT" \
    start

sleep 3

log "检查 postgres 进程"
ps aux | grep postgres | grep -v grep || true

log "验证 PostgreSQL 实例版本"
psql -h "$SOCKET_DIR" -p $PORT -d postgres -c "SELECT version();"

# ================= Step 5: 创建数据库 =================
log "=== Step 5: 创建数据库 ==="

createdb -h "$SOCKET_DIR" -p $PORT regression

# ================= Step 6: 执行 SQL =================
log "=== Step 6: 执行 SQL workload ==="

TOTAL_CASES_EST=$(grep -cE "^-- (===== Test Case|Source: debug_task_|Test [0-9]+|Test [Cc]ase [0-9]+)" "$CUSTOM_SQL_FILE" || true)
log "总 Test Case 数(预): $TOTAL_CASES_EST"

set +e
psql -h "$SOCKET_DIR" -p $PORT -d regression -f "$CUSTOM_SQL_FILE" -a > "$WORKSPACE_DIR/psql_output.log" 2>&1
PSQL_EXIT=$?
set -e

AWK_OUT=$(awk '
BEGIN { t=0; h=0; f=0; a=0 }
/^-- (===== Test Case|Source: debug_task_|Test [0-9]+|Test [Cc]ase [0-9]+)/ {
    if (a && h) { t++; fl[t]=f }
    h=0; f=0; a=1
    next
}
/ERROR:/ { if (a) f=1 }
{ if (a && !/^[[:space:]]*(--|$)/) h=1 }
END {
    if (a && h) { t++; fl[t]=f }
    s=0; for(i=1;i<=t;i++) if(!fl[i]) s++
    printf "%d %d %d\n", t, s, t-s
}
' "$WORKSPACE_DIR/psql_output.log")

if [ -z "$AWK_OUT" ]; then
    TOTAL_CASES=0
    SUCCESS_CASES=0
    FAILED_CASES=0
else
    TOTAL_CASES=$(echo "$AWK_OUT" | awk '{print $1}')
    SUCCESS_CASES=$(echo "$AWK_OUT" | awk '{print $2}')
    FAILED_CASES=$(echo "$AWK_OUT" | awk '{print $3}')
fi
TOTAL_CASES=${TOTAL_CASES:-0}
SUCCESS_CASES=${SUCCESS_CASES:-0}
FAILED_CASES=${FAILED_CASES:-0}
if [ "$TOTAL_CASES" -gt 0 ]; then
    CASE_SUCCESS_RATE=$(echo "scale=4; $SUCCESS_CASES / $TOTAL_CASES * 100" | bc)
else
    CASE_SUCCESS_RATE=0
fi

TOTAL_STMTS=$(grep -o ";" "$CUSTOM_SQL_FILE" | wc -l | awk '{print $1; exit}')
ERROR_STMTS=$(grep -c "ERROR:" "$WORKSPACE_DIR/psql_output.log" 2>/dev/null || true)
ERROR_STMTS=$(echo "$ERROR_STMTS" | awk '{print $1; exit}')
ERROR_STMTS=${ERROR_STMTS:-0}
if [ "$TOTAL_STMTS" -gt 0 ]; then
    STMT_SUCCESS_RATE=$(echo "scale=4; ($TOTAL_STMTS - $ERROR_STMTS) / $TOTAL_STMTS * 100" | bc)
else
    STMT_SUCCESS_RATE=0
fi

log "========== SQL 执行统计 =========="
log "[Case 级] 总计: $TOTAL_CASES case, 成功: $SUCCESS_CASES, 失败: $FAILED_CASES, 成功率: ${CASE_SUCCESS_RATE}%"
log "[SQL 级]  总计: $TOTAL_STMTS 条, 成功: $((TOTAL_STMTS - ERROR_STMTS)), 失败: $ERROR_STMTS, 成功率: ${STMT_SUCCESS_RATE}%"

# ================= Step 7: 停止数据库 =================
log "=== Step 7: 停止 PostgreSQL（写入 gcda）==="

"$PG_INSTALL_DIR/bin/pg_ctl" \
    -D "$MY_TEST_DATA" \
    stop -m fast

sleep 6

# ================= Step 8: 检查 gcda =================
log "=== Step 8: 检查覆盖率数据 ==="

TOTAL_GCDA=$(find "$PG_SOURCE_DIR" -name "*.gcda" | wc -l)
BACKEND_GCDA=$(find "$PG_SOURCE_DIR/src/backend" -name "*.gcda" | wc -l)
GCNO_COUNT=$(find "$PG_SOURCE_DIR/src/backend" -name "*.gcno" | wc -l)

echo "总 gcda 文件数: $TOTAL_GCDA"
echo "backend gcda 文件数: $BACKEND_GCDA"
echo "backend gcno 文件数: $GCNO_COUNT"

if [ "$BACKEND_GCDA" -lt 100 ]; then
    err "backend 覆盖率几乎没有，说明 SQL 没执行到内核！"
    exit 1
fi

# ================= Step 9: 覆盖率报告（v5: 含分支覆盖率） =================
log "=== Step 9: 生成覆盖率报告 ==="

cd "$PG_SOURCE_DIR"

LCOV_OPTS=""
GENHTML_OPTS=""
if [ "$ENABLE_BRANCH_COVERAGE" = "1" ]; then
    LCOV_OPTS="--rc lcov_branch_coverage=1"
    GENHTML_OPTS="--branch-coverage"
    log "分支覆盖率已启用"
fi

lcov --capture $LCOV_OPTS \
    --ignore-errors "$LCOV_IGNORE_ERRORS" \
    --directory "$PG_SOURCE_DIR" \
    --output-file "$WORKSPACE_DIR/coverage.info"

lcov $LCOV_OPTS \
    --ignore-errors "$LCOV_IGNORE_ERRORS" \
    --remove "$WORKSPACE_DIR/coverage.info" '/usr/*' \
    --output-file "$WORKSPACE_DIR/coverage_filtered.info"

genhtml $GENHTML_OPTS \
    --ignore-errors "$LCOV_IGNORE_ERRORS" \
    "$WORKSPACE_DIR/coverage_filtered.info" \
    --output-directory "$REPORT_DIR"

# ================= 覆盖率摘要 =================
log "=== 覆盖率摘要 ==="

LINE_COVERAGE=$(lcov --summary "$WORKSPACE_DIR/coverage_filtered.info" 2>&1 | grep "lines......" | awk '{print $2}' | tr -d '%')
FUNC_COVERAGE=$(lcov --summary "$WORKSPACE_DIR/coverage_filtered.info" 2>&1 | grep "functions." | awk '{print $2}' | tr -d '%')

if [ "$ENABLE_BRANCH_COVERAGE" = "1" ]; then
    BRANCH_COVERAGE=$(lcov --summary "$WORKSPACE_DIR/coverage_filtered.info" 2>&1 | grep "branches." | awk '{print $2}' | tr -d '%')
    log "行覆盖率: ${LINE_COVERAGE}%"
    log "函数覆盖率: ${FUNC_COVERAGE}%"
    log "分支覆盖率: ${BRANCH_COVERAGE}%"
else
    log "行覆盖率: ${LINE_COVERAGE}%"
    log "函数覆盖率: ${FUNC_COVERAGE}%"
    log "分支覆盖率: 未启用"
fi

# ================= Step 10: Recall 评测 =================
log "=== Step 10: Recall/Precision 评测 ==="

if [ -f "$JSON_DATASET_FILE" ]; then
    log "运行 recall 评测: JSON=$JSON_DATASET_FILE, COVERAGE=$WORKSPACE_DIR, OUTPUT=$EVAL_RESULT_PATH"
    python3 "$EVAL_SCRIPT" "$JSON_DATASET_FILE" "$WORKSPACE_DIR" "$EVAL_RESULT_PATH"
    log "Recall 评测完成，结果已保存到: $EVAL_RESULT_PATH"
else
    err "JSON 数据集文件不存在: $JSON_DATASET_FILE，跳过 recall 评测"
fi

# ================= 完成 =================
log "=== 完成 ==="
log "报告路径: file://$REPORT_DIR/index.html"
log "Case 级 SQL 执行成功率: ${CASE_SUCCESS_RATE}%  ($SUCCESS_CASES/$TOTAL_CASES)"
if [ "$ENABLE_BRANCH_COVERAGE" = "1" ]; then
    log "分支覆盖率: ${BRANCH_COVERAGE}%"
fi

# 清理本次运行产生的 gcda，保留 gcno 以便 --skip-build 复用 coverage 编译结果。
find "$PG_SOURCE_DIR" -name "*.gcda" -delete
log "gcda 已清理，gcno 已保留"
