# PostgreSQL SQL 测试用例生成大作业

## 任务概述

本课程大作业要求同学们**针对 PostgreSQL 内核代码变更，设计 Prompt 来生成 SQL 测试用例**，目标是尽可能覆盖 commit 中新增/修改的 PostgreSQL C 代码路径。

每个同学需要阅读给定的 PostgreSQL commit diff，通过 Prompt Engineering、SFT 微调或混合方法生成 SQL 测试语句，最终提交一个 JSON 文件到打榜平台。平台会自动执行 SQL 并评测覆盖率得分。

本目录提供一套本地自测工具，帮助你在上传平台前检查：

- submission JSON 格式是否正确
- SQL 是否能被平台脚本提取
- SQL 在本地 PostgreSQL coverage 版本上是否能执行
- 本地预估的 `global_precision_excl_not_found`

本地评测结果只作为参考，最终分数以打榜平台为准。

---

## 背景知识

### 代码覆盖率

代码覆盖率衡量测试用例执行时“跑到了多少源码行”。覆盖率越高，说明你的 SQL 越好地触发了 commit 新增或修改的代码逻辑。

评测流程简化如下：

```text
学生提交 JSON
      ↓
提取 <sql>...</sql> 标签中的 SQL
      ↓
平台执行 SQL（psql -f）
      ↓
gcov/lcov/genhtml 收集覆盖率数据
      ↓
评测脚本比对 commit 新增代码行与 coverage 报告
      ↓
输出 Recall / Precision 等指标
```

---

## 参考运行环境

平台环境可能与同学本机不同。为了尽量接近平台，可参考以下版本：

```text
GCC:  GCC 11.2.1 (devtoolset-11)
gcov: GCC 11.2.1 (devtoolset-11)
lcov: 1.16
```

本地如果使用 macOS Apple clang、LLVM gcov 或较新的 lcov，也可以运行本工具包，但覆盖率 HTML 细节可能和平台略有差异。因此本地分数只用于自查，最终排名以平台结果为准。

---

## 数据说明

### 测试集 `data/test_v3.json`

- 共 50 个 PostgreSQL commit 记录
- 每条记录包含：
  - `id`：唯一标识，提交 JSON 中必须使用相同 id
  - `subject`：commit 标题
  - `email_body`：commit 描述
  - `patches`：代码 diff，包括 `raw_diff` 和 `diff_blocks`
  - `match_info`：代码行级匹配信息，用于和 coverage 报告对齐

### 训练集 `data/train.json`

- 共 100 条记录
- 结构与测试集类似
- 额外包含 `generated_sql_tests` 字段，可作为参考样例或 SFT 训练数据

### PostgreSQL 源码

工具包内提供：

```text
postgresql-13.23.tar.bz2
```

首次本地评测时，如果没有解压后的 `postgresql-13.23/` 目录，脚本会自动从该压缩包解压。

---

## 工具包目录结构

```text
student_dataset_upload/
  README.md
  requirements.txt
  postgresql-13.23.tar.bz2
  run_local_eval.sh
  scripts/
    generate_submission.py
    evaluate.py
    evaluate_coverage.sh
  data/
    test_v3.json
    train.json
  examples/
    example_submission.json
  outputs/
```

脚本说明：

| 文件 | 说明 |
|---|---|
| `scripts/generate_submission.py` | 调用 ChatECNU API，根据 commit diff 生成 submission JSON |
| `scripts/evaluate.py` | 统一处理 submission 检查、SQL 提取、coverage 指标计算和平台输出 |
| `scripts/evaluate_coverage.sh` | 编译 PostgreSQL、执行 SQL、生成 coverage 报告、调用评测 |
| `run_local_eval.sh` | 推荐使用的一键本地评测入口 |

---

## 提交格式

最终上传平台的是一个 JSON 文件，结构如下：

```json
[
  {
    "id": 101,
    "generated_sql_tests": "<test_cases>\n  <test_case id=\"1\">\n    <description>测试 xxx 代码路径</description>\n    <sql>\n-- Setup\nDROP TABLE IF EXISTS test_t1 CASCADE;\nCREATE TABLE test_t1 (id INT);\nINSERT INTO test_t1 VALUES (1);\n\n-- Execution\nSELECT * FROM test_t1 WHERE id = 1;\n\n-- Teardown\nDROP TABLE IF EXISTS test_t1 CASCADE;\n    </sql>\n  </test_case>\n</test_cases>"
  }
]
```

要求：

1. 顶层必须是 JSON 数组
2. 每个元素必须包含 `id` 和 `generated_sql_tests`
3. `id` 必须与 `data/test_v3.json` 中的 commit id 对应
4. `generated_sql_tests` 中用 `<test_cases>...</test_cases>` 包裹测试用例
5. 每个 `<test_case>` 建议包含 `<description>` 和 `<sql>`
6. 平台会提取 `<sql>...</sql>` 标签里的 SQL 执行
7. SQL 应尽量自包含：建表、插入数据、执行目标 SQL、清理对象

---

## 评分指标

评测脚本会输出多个指标，其中本课程当前重点关注：

```text
global_precision_excl_not_found
```

相关字段说明：

| 指标 | 含义 |
|---|---|
| `total_meaningful_added` | commit 中有意义的新增代码行数 |
| `total_matched` | 能在源码/报告中定位到的目标代码行数 |
| `total_not_found` | coverage 报告中找不到的行数 |
| `total_covered` | 实际被 SQL 执行覆盖到的目标代码行数 |
| `global_recall` | `total_matched / total_meaningful_added` |
| `global_precision` | `total_covered / total_matched` |
| `global_precision_excl_not_found` | `total_covered / (total_matched - total_not_found)` |

如果本地环境和平台环境不同，`not_found` 和 coverage HTML 解析结果可能略有差别。因此本地 `global_precision_excl_not_found` 是上传前参考值，不保证与平台完全一致。

---

## 环境准备

### Python 依赖

```bash
python3 -m pip install -r requirements.txt
```

建议使用 Python 3.10 或更新版本。`scripts/evaluate.py` 的格式检查、SQL 提取和指标计算只依赖标准库；只有调用 `scripts/generate_submission.py` 生成提交时才需要 `openai` 包和 API Key。

### 本地完整评测环境

`run_local_eval.sh` 和 `scripts/evaluate_coverage.sh` 需要 Bash 环境，适合在 Linux、macOS 或 WSL 中运行；Windows PowerShell 可以运行 Python 格式检查，但不能直接执行 `.sh` 评测脚本。

### macOS 依赖示例

```bash
brew install lcov bison flex readline openssl@3
```

### Linux 参考

推荐使用接近平台的环境：

```text
GCC 11.2.1 (devtoolset-11)
lcov 1.16
```

完整评测还需要常见编译工具和命令，包括 `make`、`tar`、`awk`、`bc`、`lcov`、`genhtml`，以及 PostgreSQL 编译所需的 `bison`、`flex`、`readline` 等开发库。如果你使用其它版本，也可以本地自测，但最终请以平台结果为准。

---

## 快速检查 submission

不编译 PostgreSQL，只检查格式和 SQL case 数：

```bash
python3 scripts/evaluate.py check outputs/submission.json
```

检查示例 submission：

```bash
python3 scripts/evaluate.py check examples/example_submission.json
```

---

## 一键本地评测

### 方式一：从 submission JSON 评测

把你的提交文件放到：

```text
outputs/submission.json
```

首次完整评测：

```bash
./run_local_eval.sh --submission outputs/submission.json --name my_submission
```

如果 PostgreSQL 已经编译过，可以跳过编译：

```bash
./run_local_eval.sh --submission outputs/submission.json --name my_submission --skip-build
```

### 方式二：直接使用合并好的 SQL 文件

如果你已经准备好了合并后的 SQL 文件，例如 `outputs/all_gen_sql.sql`：

```bash
./run_local_eval.sh --sql outputs/all_gen_sql.sql --name all_gen_sql
```

后续复用编译结果：

```bash
./run_local_eval.sh --sql outputs/all_gen_sql.sql --name all_gen_sql --skip-build
```

### 设置最低本地分数

如果希望本地 `global_precision_excl_not_found` 低于某个值时直接失败：

```bash
./run_local_eval.sh \
  --submission outputs/submission.json \
  --name my_submission \
  --skip-build \
  --min-score 0.3
```

---

## 查看评测结果

一键评测结果保存在：

```text
outputs/local_eval/<name>/
```

重点文件：

```text
outputs/local_eval/<name>/summary.txt
outputs/local_eval/<name>/eval_result.json
outputs/local_eval/<name>/coverage_workspace/report/index.html
outputs/local_eval/<name>/coverage_workspace/psql_output.log
outputs/local_eval/<name>/coverage_workspace/run.log
```

查看主指标：

```bash
cat outputs/local_eval/<name>/summary.txt
```

查看完整 JSON：

```bash
python3 - <<'PY'
import json
with open("outputs/local_eval/<name>/eval_result.json", encoding="utf-8") as f:
    data = json.load(f)
print(json.dumps(data["summary"], ensure_ascii=False, indent=2))
PY
```

检查 SQL 报错：

```bash
grep -n "ERROR:" outputs/local_eval/<name>/coverage_workspace/psql_output.log | head -50
```

打开 HTML 覆盖率报告：

```text
outputs/local_eval/<name>/coverage_workspace/report/index.html
```

---

## 生成 submission

如果你要直接调用 ChatECNU API 生成：

```bash
export CHAT_ECNU_API_KEY="你的 ChatECNU API Key"
python3 scripts/generate_submission.py \
  -i data/test_v3.json \
  -o outputs/submission.json
```

调试时只生成前 1 条：

```bash
python3 scripts/generate_submission.py \
  -i data/test_v3.json \
  -o outputs/sample_submission.json \
  --limit 1
```

生成后建议先检查：

```bash
python3 scripts/evaluate.py check outputs/submission.json
```

---

## 手动分步评测

如果不使用一键脚本，也可以手动执行。

从 submission 中提取 SQL：

```bash
python3 scripts/evaluate.py extract \
  -i outputs/submission.json \
  -m outputs/all_gen_sql.sql
```

完整编译并评测：

```bash
scripts/evaluate_coverage.sh \
  --sql outputs/all_gen_sql.sql \
  --dataset data/test_v3.json \
  --eval-output outputs/eval_result.json \
  --workspace outputs/coverage_workspace \
  --no-branch-coverage
```

复用编译结果：

```bash
scripts/evaluate_coverage.sh \
  --skip-build \
  --sql outputs/all_gen_sql.sql \
  --dataset data/test_v3.json \
  --eval-output outputs/eval_result.json \
  --workspace outputs/coverage_workspace \
  --no-branch-coverage
```

---

## 做法建议

### Prompt Engineering

可以参考 `scripts/generate_submission.py` 中的 prompt 模板。建议 prompt 明确要求：

- 分析 commit diff 的代码路径
- 覆盖正常路径
- 覆盖边界情况，如 NULL、空表、重复值、特殊类型
- 覆盖错误触发路径
- SQL 自包含，包含 setup / execution / teardown
- 输出严格遵循 `<test_cases>` 和 `<sql>` 标签格式

### SFT 微调

可以使用 `data/train.json` 中的：

```text
subject / email_body / patches -> generated_sql_tests
```

作为监督微调样本。

### 混合方案

可以先用模型生成初版，再根据本地 `psql_output.log` 和 coverage 结果补充低覆盖 commit 的 SQL。

---

## 常见问题

**Q：SQL 执行报错会影响分数吗？**

A：报错 SQL 不会贡献覆盖率，但通常不会直接扣分。不过它会占用 SQL case 配额，也会浪费执行时间，建议尽量减少。

**Q：本地分数和平台不一致怎么办？**

A：这是正常的。编译器、gcov/lcov/genhtml 版本、系统环境、路径和 locale 都可能影响 coverage 报告。最终以平台分数为准。

**Q：本地应该看哪个指标？**

A：重点看 `summary.global_precision_excl_not_found`，同时检查 `psql_output.log` 中的 SQL 报错。

**Q：为什么默认关闭 branch coverage？**

A：本任务主要看行级覆盖。macOS 或 LLVM gcov 环境下，branch coverage 容易触发 lcov/genhtml 兼容问题，所以本地默认关闭更稳定。

**Q：PostgreSQL socket 路径过长怎么办？**

A：脚本默认使用 `/tmp/pgcov-55432` 作为 socket 目录，避免项目路径过长导致 socket 创建失败。

**Q：端口冲突怎么办？**

A：一键脚本可指定端口：

```bash
./run_local_eval.sh --submission outputs/submission.json --name my_submission --port 55433
```

---

## 平台 Evaluation

Evaluation平台提交链接：https://pg-leaderboard-deeplearning.loca.lt/leaderboard


用于平台排序的指标为：

```text
PrecNF
efficiency
```

平台排序配置为：

| 指标 | 排序 |
|---|---|
| `PrecNF` | 降序，越大越好 |
| `efficiency` | 升序，越小越好 |

其中 `PrecNF` 对应评测脚本里的 `global_precision_excl_not_found`。

`efficiency` 是用于同 `PrecNF` 情况下比较 SQL 使用效率的代价值，计算方式为：

```text
efficiency = (sql_count ^ 0.35) / (PrecNF * 100)
```

其中 `sql_count` 统计的是 `<sql>...</sql>` 中的实际 SQL 语句数，而不是 `<sql>` 标签数量。计数时按顶层分号拆分，注释、字符串、quoted identifier 和 PostgreSQL dollar-quoted 函数体里的分号不会被当作新语句。`sql_count` 只用于计算 `efficiency`，不作为平台的单独排序指标。评测失败时，脚本会给 `PrecNF` 写 `0.000000`，给 `efficiency` 写一个较大的默认值。

---

## 上传平台前建议流程

1. 生成或准备 `outputs/submission.json`
2. 运行格式检查：

```bash
python3 scripts/evaluate.py check outputs/submission.json
```

3. 运行本地评测：

```bash
./run_local_eval.sh --submission outputs/submission.json --name my_submission
```

4. 查看：

```bash
cat outputs/local_eval/my_submission/summary.txt
grep -n "ERROR:" outputs/local_eval/my_submission/coverage_workspace/psql_output.log | head -50
```

5. 如果本地结果可以接受，上传原始 `outputs/submission.json` 到打榜平台。
