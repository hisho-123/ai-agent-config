# 共通skills

## 登録済みスキル

- [git-commit-push](git-commit-push/SKILL.md): 明示的に指示されたコミット・プッシュだけを実行します。プッシュにはSSHを使い、具体的なコマンドと実行条件を記載しています。
- [github-pr-create](github-pr-create/SKILL.md): 明示的なPR作成依頼に対して、差分の分析、日本語のタイトル・説明文の作成、プッシュ、GitHub CLIによるPR作成・確認を実行します。

## 追加方法

自作の汎用スキルを、次のようにスキル単位のディレクトリに追加します。

```text
skills/
└── my-skill/
    ├── SKILL.md
    ├── scripts/       # 任意
    ├── references/    # 任意
    └── assets/        # 任意
```

`SKILL.md`の最小例:

```markdown
---
name: my-skill
description: このスキルを使う具体的な作業と条件を書く。
---

# My skill

作業手順、必要な入力、期待する成果物を書く。
```

追加後、リポジトリのルートで`./install.sh --dry-run`、続いて`./install.sh`を実行します。
直下のディレクトリごとに`SKILL.md`が必要です。READMEなどの直下の通常ファイルは配置しません。

ディレクトリ名とスキル名は他のスキルと重複しない名前にしてください。
組み込み・プラグインのスキルはこのリポジトリにコピーせず、それぞれの仕組みで管理します。
プロジェクト固有のスキルは、そのリポジトリの`.agents/skills/`に置きます。

[公式ドキュメント](https://learn.chatgpt.com/docs/build-skills)
