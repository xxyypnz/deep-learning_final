# GUIDE_pnz — PostgreSQL SQL Test Generation

> 本文件是本项目的主操作手册，所有后续内容在此精修。
> 最后更新：2026-05-29

---

## 0. 任务一句话总结

给定 50 个 PostgreSQL commit 的 C 代码 diff，生成 SQL 测试用例，使这些 SQL 执行后能覆盖尽可能多的新增/修改代码行。主指标是 **PrecNF（越高越好）**。

---

## 1. 项目结构

```
deep-learning/
├── README.md                  # 官方说明（必读）
├── START_HERE.md              # 快速入门
├── final.pdf                  # 课程 slides（Lab12）
├── requirements.txt           # openai>=1.0.0, beautifulsoup4>=4.12.0
├── sample.ipynb               # 提交格式模板
├── run_local_eval.sh          # 一键本地评测脚本
├── postgresql-13.23.tar.bz2   # PostgreSQL 源码（用于编译覆盖率）
├── data/
│   ├── train.json             # 100 条训练数据（含参考 SQL）
│   └── test_v3.json           # 50 条测试数据（需要生成 SQL）
├── examples/
│   └── example_submission.json
├── scripts/
│   ├── evaluate.py            # 格式检查 / 指标计算
│   ├── evaluate_coverage.sh   # 覆盖率评测流水线
│   └── generate_submission.py # 调用 ChatECNU API 生成 SQL
└── outputs/                   # 【需手动创建】提交文件放这里
    └── submission.json
```

---

## 2. 提交格式

文件路径：`outputs/submission.json`

```json
[
  {
    "id": 101,
    "generated_sql_tests": "<test_cases>\n  <test_case id=\"1\">\n    <description>测试描述</description>\n    <sql>\nDROP TABLE IF EXISTS t CASCADE;\nCREATE TABLE t (id INT);\nSELECT * FROM t;\nDROP TABLE IF EXISTS t CASCADE;\n    </sql>\n  </test_case>\n</test_cases>"
  },
  ...
]
```

**硬性要求：**
- 顶层是 JSON 数组
- 每条有 `id`（对应 test_v3.json）和 `generated_sql_tests`
- SQL 必须包在 `<sql>...</sql>` 标签内
- 每个 test_case 要自包含（建表 → 执行 → 清理）
- 避免死锁、无限递归、长时间执行

---

## 3. 评测指标

| 指标 | 公式 | 方向 |
|------|------|------|
| **PrecNF**（主指标） | `total_covered / (total_matched - total_not_found)` | 越高越好 |
| efficiency（次指标） | `(sql_count^0.35) / (PrecNF * 100)` | 越低越好 |

- `total_matched`：commit 新增行中能在覆盖率报告里找到的行数
- `total_not_found`：找不到的行（排除在分母外）
- `total_covered`：被 SQL 实际执行到的行数
- `sql_count`：提交中 SQL 语句总数（影响 efficiency）

---

## 4. 快速跑通 Baseline（第一次提交全流程）

### Step 1：安装依赖

```bash
cd /c/2026-06-01/deep-learning
pip install -r requirements.txt
```

### Step 2：生成 Baseline 提交文件

最简单的 baseline：用 `scripts/generate_submission.py` 调 ChatECNU API。

**前提：** 需要 `CHAT_ECNU_API_KEY` 环境变量。

```bash
export CHAT_ECNU_API_KEY="你的key"
python3 scripts/generate_submission.py \
    --dataset data/test_v3.json \
    --output outputs/submission.json \
    --model ecnu-plus \
    --n 3
```

参数说明：
- `--model`：`ecnu-plus`（快）或 `ecnu-max`（强）
- `--n`：每个 commit 生成几个 test case，建议先用 3
- 脚本支持断点续跑（已生成的 id 会跳过）

**如果没有 API key，用最小 baseline（格式正确但 SQL 为空）：**

```bash
mkdir -p outputs
python3 - <<'EOF'
import json

with open("data/test_v3.json") as f:
    data = json.load(f)

submission = []
for item in data:
    submission.append({
        "id": item["id"],
        "generated_sql_tests": '<test_cases>\n  <test_case id="1">\n    <description>Basic smoke test</description>\n    <sql>\nSELECT 1;\n    </sql>\n  </test_case>\n</test_cases>'
    })

with open("outputs/submission.json", "w") as f:
    json.dump(submission, f, indent=2)

print(f"Generated {len(submission)} entries")
EOF
```

### Step 3：格式检查

```bash
python3 scripts/evaluate.py check outputs/submission.json --dataset data/test_v3.json
```

输出 `All checks passed` 才能继续。常见错误：
- id 数量不对（必须 50 条）
- 缺少 `<sql>` 标签
- JSON 格式错误

### Step 4：本地覆盖率评测（可选，需要 Linux 环境）

> Windows 上直接跳到 Step 5 提交平台。本地评测需要 GCC、lcov，建议在 WSL 或 Linux 机器上跑。

```bash
# 在 WSL/Linux 中：
chmod +x run_local_eval.sh
./run_local_eval.sh \
    --submission outputs/submission.json \
    --name baseline_v1

# 查看结果
cat outputs/local_eval/baseline_v1/summary.txt
```

首次运行会编译 PostgreSQL（约 10-20 分钟），之后可加 `--skip-build` 跳过编译。

### Step 5：上传到平台

- 平台地址：https://pg-leaderboard-deeplearning.loca.lt/leaderboard
- 上传 `outputs/submission.json`
- 每人每天最多 5 次提交，取最高分

---

## 5. 数据格式速查

### test_v3.json 单条结构

```
{
  "id": 101,
  "subject": "commit 标题",
  "patches": [
    {
      "file": "src/backend/xxx.c",
      "function": "函数名",
      "before_code": [...],   // 修改前代码行
      "after_code": [...],    // 修改后代码行
      "raw_diff": "...",      // unified diff
      "diff_blocks": [...]    // 分块 diff
    }
  ],
  "match_info": {
    "patches": [
      {
        "file": "...",
        "blocks": [
          {
            "matched": true,
            "lines": [{"source_line": 123, "code": "..."}]
          }
        ]
      }
    ]
  }
}
```

关键字段：
- `patches[].raw_diff`：最直接的 diff，用于 prompt
- `patches[].after_code`：修改后的完整函数代码
- `match_info`：评测时用来定位目标行，生成时可忽略

### train.json 额外字段

```
"generated_sql_tests": "<test_cases>...</test_cases>"
```

可直接作为 few-shot 示例或 SFT 训练数据。

---

## 6. generate_submission.py 核心逻辑

脚本向 ChatECNU API 发送如下 prompt（简化版）：

```
你是 PostgreSQL 专家。分析以下 commit diff，生成 N 个自包含的 SQL 测试用例。
要求覆盖：正常路径、边界情况（NULL/空/重复）、错误路径。

Commit: {subject}
Diff:
{raw_diff}

输出格式：
<test_cases>
  <test_case id="1">
    <description>...</description>
    <sql>...</sql>
  </test_case>
</test_cases>
```

API 配置：
- Base URL: `https://chat.ecnu.edu.cn/open/api/v1`
- 模型: `ecnu-plus` / `ecnu-max`
- 环境变量: `CHAT_ECNU_API_KEY`

---

## 7. 常见问题

**Q: `check` 报 "id not found"**
A: 检查 submission.json 的 id 是否和 test_v3.json 完全一致（共 50 个）。

**Q: 本地评测报 "psql: could not connect"**
A: PostgreSQL 没启动或端口冲突，检查 `/tmp/pgcov-55432` socket 是否存在，或换端口 `--port 55433`。

**Q: 本地评测在 Windows 上失败**
A: `run_local_eval.sh` 依赖 GCC/lcov，必须在 WSL 或 Linux 上运行。Windows 只能做格式检查。

**Q: efficiency 很高（差）**
A: 减少 SQL 语句数量，或提高 PrecNF。每个 test_case 里的 SQL 语句数直接影响 sql_count。

**Q: PrecNF 为 0**
A: SQL 没有执行到任何目标行。检查 SQL 是否真的触发了 commit 修改的函数/代码路径。

---

## 8. 改进方向（后续迭代）

| 方向 | 思路 | 预期收益 |
|------|------|----------|
| Prompt 优化 | 在 prompt 中加入 `after_code` 完整函数体，让模型看到更多上下文 | 中 |
| Few-shot | 从 train.json 中检索相似 commit，加入 prompt 作为示例 | 中-高 |
| 多样性 | 每个 commit 生成更多 test case，覆盖更多分支 | 中 |
| SFT | 用 train.json 微调模型 | 高（成本高） |
| 后处理 | 过滤掉执行报错的 SQL，只保留有效的 | 低-中 |

---

## 9. 提交检查清单

- [ ] `outputs/submission.json` 存在
- [ ] `python3 scripts/evaluate.py check outputs/submission.json --dataset data/test_v3.json` 通过
- [ ] 共 50 条记录，id 与 test_v3.json 一致
- [ ] 每条都有 `<sql>` 标签
- [ ] 上传平台，确认分数已记录
- [ ] 截止日期：**2026-06-21**

---

*本文件持续更新，每次迭代在此追加记录。*
