# 共通skills

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
