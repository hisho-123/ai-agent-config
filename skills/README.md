# 共通skills

## 登録済みスキル

- [coding](coding/SKILL.md): GPT-6.1 Solの高で実装し、GPT-6 Astraのウルトラによる独立レビューと同一agentでの修正を指摘ゼロまで反復します。通常の実装依頼に対し、コミット・SSHプッシュ・PR作成まで進めます。
- [review](review/SKILL.md): GPT-6 Astraのウルトラによる独立レビューとGPT-6.1 Solの高による同一agentでの修正を指摘ゼロまで反復します。通常のレビュー依頼に対し、修正・コミット・SSHプッシュまで進め、PRは作成しません。
- [spec-review](spec-review/SKILL.md): 仕様書レビューの観点と判定方法を定めます。完全性・明確性・整合性・妥当性・テスト可能性に加え、追跡可能性、セキュリティ、非機能・運用、互換性・移行、使いやすさ等を確認します。
- [implementation-review](implementation-review/SKILL.md): 実装レビューの観点と検証・報告方法を定めます。仕様準拠・正確性・設計・データ整合・保守性・テスト品質に加え、セキュリティ、性能、信頼性、互換性・移行、運用、使いやすさ等を確認します。
- [test-design](test-design/SKILL.md): アプリ実装時の参照元とテストコード生成・実行の基準になる、単体・結合・Playwright E2Eのテスト設計書を実装前に`{{サービス名}}_docs`内へ作成・更新します。設計書テンプレートを備え、C0/C1の100%、P0/P1の100%実装・成功、全レベルを合わせた要件カバレッジ100%、Flaky 0を目標に測定・判定方法を定めます。
- [git-commit-push](git-commit-push/SKILL.md): 通常の実装・レビュー依頼や明示的な操作指示に基づき、対象変更をコミット・SSHプッシュします。差分の目的・性質ごとにコミットを分け、PR作成に必要なプッシュも行います。
- [github-pr-create](github-pr-create/SKILL.md): PR作成依頼を必要なプッシュの許可も含むものとして扱い、差分の分析、日本語のタイトル・説明文の作成、SSHプッシュ、GitHub CLIによるPR作成・確認を実行します。

`coding`・`review`は作業の進め方、`spec-review`・`implementation-review`は対象ごとの評価基準を担います。前者はレビュー対象に応じて後者を参照し、レビュアーにも参照先を渡します。観点スキルだけを使う場合は、対象の変更やコミット等を行わず、レビュー結果を報告します。

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
