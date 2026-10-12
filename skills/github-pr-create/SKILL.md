---
name: github-pr-create
description: GitHub CLI（gh）を使用して、現在のブランチからPull Requestを作成する。
---

# GitHub PR作成

## 手順

1. 以下を実行して、現在の状態を確認する。

   ```bash
   git status --short --branch
   git branch --show-current
   gh auth status
   ```

2. マージ先はユーザー指定を優先し、指定がなければデフォルトブランチを使用する。

3. マージ先ブランチとの差分とコミット履歴を確認する。

   ```bash
   git fetch origin <base>
   git log --oneline origin/<base>..HEAD
   git diff origin/<base>...HEAD
   ```

4. `gh pr list` で同じブランチの既存PRを確認し、重複作成を避ける。

5. 差分をもとに、日本語でPRタイトルと本文を生成する。

   タイトルは `feat: ○○を追加` のような形式にする。

   本文は以下の形式とする。

   ```markdown
   ## 概要
   変更の目的を記載する。

   ## 変更内容
   - 主な変更点

   ## テスト
   - 実施したテストと結果
   ```

6. 必要に応じて `git push -u origin HEAD` でPushし、PRを作成する。

   ```bash
   gh pr create \
     --base <base> \
     --title "<title>" \
     --body-file <body-file>
   ```

7. 作成したPRのURLをユーザーに報告する。

## ルール

- 未コミットの変更は勝手にコミットしない。
- PR本文には実際の変更内容のみ記載する。
- 実施していないテストを実施済みと記載しない。
- 強制PushやPRのマージは行わない。
- ユーザーが指定した場合のみDraft PRを作成する。

