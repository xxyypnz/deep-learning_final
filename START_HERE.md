# 作业说明

请阅读本目录下的 `README.md`，并使用平台根目录中的 `sample.ipynb` 作为模板。

## 你需要做什么

根据：

```text
data/test_v3.json
```

为每个 PostgreSQL commit 生成 SQL 测试用例，并最终保存：

```text
outputs/submission.json
```

## 提交格式

`submission.json` 顶层是数组，每项包含：

```json
{
  "id": 1,
  "generated_sql_tests": "<test_cases>...<sql>SELECT ...;</sql>...</test_cases>"
}
```

平台会提取 `<sql>...</sql>` 中的 SQL 执行。

## 快速检查

```bash
python3 scripts/evaluate.py check outputs/submission.json --dataset data/test_v3.json
```

## 本地完整评测

如果你的环境支持编译 PostgreSQL、`gcov`、`lcov`，可以参考：

```bash
./run_local_eval.sh --submission outputs/submission.json --name my_submission
```

最终分数以平台线上评测为准。
