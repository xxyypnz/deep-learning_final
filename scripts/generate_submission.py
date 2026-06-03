import json
import os
import time
import argparse
from pathlib import Path

TOOLKIT_DIR = Path(__file__).resolve().parents[1]
CHAT_ECNU_BASE_URL = "https://chat.ecnu.edu.cn/open/api/v1"
CHAT_ECNU_DEFAULT_MODEL = "ecnu-max" # 或"ecnu-max"
CHAT_ECNU_DEFAULT_API_KEY = "sk-75e55c99c4464b159baf021b14e1cf1f" # 请替换为你的实际API Key, 或export CHAT_ECNU_API_KEY="你的API Key"


def default_test_file():
    for name in ("test_v3.json", "test_v3(1).json"):
        candidate = TOOLKIT_DIR / "data" / name
        if candidate.exists():
            return candidate
    return TOOLKIT_DIR / "data" / "test_v3.json"


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else [data]


def save_submission(records, output_path):
    output_path.parent.mkdir(parents=True, exist_ok=True)
    submission = [
        {
            "id": item.get("id"),
            "generated_sql_tests": item.get("generated_sql_tests", ""),
        }
        for item in records
    ]
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(submission, f, ensure_ascii=False, indent=2)


def load_progress(output_path):
    if not output_path.exists():
        return {}
    try:
        existing = load_json(output_path)
    except json.JSONDecodeError:
        print("输出文件格式错误或为空，将从头生成。")
        return {}
    return {
        item.get("id"): item.get("generated_sql_tests", "")
        for item in existing
        if item.get("id") is not None
        and item.get("generated_sql_tests")
        and not str(item.get("generated_sql_tests")).startswith("Generation failed")
    }


def build_prompt(commit, cases_per_commit):
    subject = commit.get("subject", "")
    message = commit.get("email_body", "")

    all_diffs = ""
    for patch in commit.get("patches", []):
        all_diffs += f"File: {patch.get('file')}\n"
        all_diffs += f"Diff:\n{patch.get('raw_diff')}\n\n"

    system_prompt = (
        "You are an expert PostgreSQL kernel developer and QA testing engineer. "
        "Your task is to generate PostgreSQL test scripts that exercise newly added or modified C code paths "
        "so that their code coverage can be measured. "
        "Output strictly using the provided XML-like tags, no extra text."
    )

    user_prompt = f"""I have modified the C source code of PostgreSQL. Below are the commit details and the code diff.

[Commit Subject]: {subject}
[Commit Message]: {message}

[Code Diff]:
{all_diffs}

Please analyze the C source code changes. Then write exactly {cases_per_commit} self-contained SQL test cases that exercise the new or modified code paths.

Requirements:
1. Coverage only — the SQL just needs to reach the new code paths. No need to verify output correctness.
2. Self-contained — each test must independently CREATE tables/data, execute the target query, and DROP afterwards.
3. Diverse — cover normal case, edge cases (NULL, empty, duplicates), invalid/error-triggering cases, and different call sites if applicable.
4. Output format — wrap everything in <test_cases>...</test_cases>, each case in <test_case id="N"> with <description> and <sql>. No markdown, no extra text outside the XML tags.

Use EXACTLY this structure:

<test_cases>
    <test_case id="1">
        <description>Briefly explain which code path this test targets.</description>
        <sql>
-- Setup
DROP TABLE IF EXISTS test_t1 CASCADE;
CREATE TABLE test_t1 (id INT);
INSERT INTO test_t1 VALUES (1);

-- Execution
SELECT * FROM test_t1 WHERE id = 1;

-- Teardown
DROP TABLE IF EXISTS test_t1 CASCADE;
        </sql>
    </test_case>
</test_cases>
"""
    return system_prompt, user_prompt, all_diffs


def generate_sql_tests_ecnu(
    input_path,
    output_path,
    model=CHAT_ECNU_DEFAULT_MODEL,
    cases_per_commit=5,
    temperature=0.2,
    max_tokens=8192,
    timeout=120,
    sleep_seconds=1.0,
    limit=None,
    resume=True,
):
    input_path = Path(input_path)
    output_path = Path(output_path)

    if not input_path.exists():
        print(f"错误：找不到输入文件 {input_path}")
        return

    api_key = (
        os.environ.get("CHAT_ECNU_API_KEY")
        or os.environ.get("ECNU_API_KEY")
        or CHAT_ECNU_DEFAULT_API_KEY
    )
    if not api_key:
        raise RuntimeError("请先设置环境变量 CHAT_ECNU_API_KEY，再运行 API 生成脚本。")

    try:
        from openai import OpenAI
    except ImportError as exc:
        raise RuntimeError("缺少依赖 openai，请先运行：python3 -m pip install -r requirements.txt") from exc

    client = OpenAI(api_key=api_key, base_url=CHAT_ECNU_BASE_URL)
    commits = load_json(input_path)
    if limit is not None:
        commits = commits[:limit]

    progress = load_progress(output_path) if resume else {}
    for commit in commits:
        commit_id = commit.get("id")
        if commit_id in progress:
            commit["generated_sql_tests"] = progress[commit_id]

    total_commits = len(commits)
    processed_ids = {
        item.get("id")
        for item in commits
        if item.get("generated_sql_tests")
        and not str(item.get("generated_sql_tests")).startswith("Generation failed")
    }
    pending_commits = total_commits - len(processed_ids)
    print(f"任务启动：共 {total_commits} 个记录，待处理 {pending_commits} 个...\n")

    for i, commit in enumerate(commits):
        commit_id = commit.get("id")

        if commit_id in processed_ids:
            continue

        system_prompt, user_prompt, all_diffs = build_prompt(commit, cases_per_commit)

        if not all_diffs.strip():
            print(f"[{i+1}/{total_commits}] Commit ID {commit_id} 没有代码变更，跳过。")
            commit["generated_sql_tests"] = "No code changes"
            save_submission(commits, output_path)
            continue

        print(f"[{i+1}/{total_commits}] 正在为 Commit ID {commit_id} 请求 ChatECNU API...")

        try:
            response = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=temperature,
                max_tokens=max_tokens,
                timeout=timeout,
                stream=False
            )

            generated_sql = response.choices[0].message.content
            commit["generated_sql_tests"] = generated_sql
            print(f"   生成成功！")

        except Exception as e:
            print(f"   API 请求失败: {e}")
            commit["generated_sql_tests"] = f"Generation failed: {e}"

        save_submission(commits, output_path)
        print(f"   进度已保存。\n")

        time.sleep(sleep_seconds)

    print(f"全部处理完成！最终结果已保存至: {output_path}")


def parse_args():
    parser = argparse.ArgumentParser(description="根据 PostgreSQL commit diff 调用 ChatECNU 生成提交 JSON。")
    parser.add_argument("-i", "--input", default=str(default_test_file()), help="测试集 JSON，默认自动使用 test_v3.json 或 test_v3(1).json")
    parser.add_argument("-o", "--output", default=str(TOOLKIT_DIR / "outputs" / "submission.json"), help="输出提交 JSON")
    parser.add_argument("--model", default=CHAT_ECNU_DEFAULT_MODEL, help="ChatECNU/OpenAI 兼容模型名")
    parser.add_argument("--cases", type=int, default=5, help="每个 commit 生成的 SQL test case 数")
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--sleep", type=float, default=1.0, help="每次 API 请求后的暂停秒数")
    parser.add_argument("--limit", type=int, default=None, help="只处理前 N 条，便于调试")
    parser.add_argument("--no-resume", action="store_true", help="不读取已有输出进度")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    try:
        generate_sql_tests_ecnu(
            args.input,
            args.output,
            model=args.model,
            cases_per_commit=args.cases,
            temperature=args.temperature,
            max_tokens=args.max_tokens,
            timeout=args.timeout,
            sleep_seconds=args.sleep,
            limit=args.limit,
            resume=not args.no_resume,
        )
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc
