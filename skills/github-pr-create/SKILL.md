---
name: github-pr-create
description: GitHub CLI（gh）を使用して現在のブランチからPull Requestを作成し、必要なSSHプッシュも行う。
---

# GitHub PR作成

## 手順

1. 以下を実行して、現在の状態を確認する。

   ```bash
   git status --short --branch
   git branch --show-current
   gh auth status
   ```

2. PRのマージ先リポジトリ（base repo）と、ブランチの送信先リポジトリ（head repo）・ブランチを、ユーザー指定と実際のプッシュ先から特定する。リポジトリは`[HOST/]OWNER/REPO`で記録する。マージ先ブランチはユーザー指定を優先し、指定がなければbase repoのデフォルトブランチを使用する。forkではbase repoとhead repoを取り違えない。

3. base repoのURLからマージ先ブランチを取得し、差分とコミット履歴を確認する。`origin`がbase repoとは限らない。

   ```bash
   git fetch <base-repo-url> refs/heads/<base>
   git log --oneline FETCH_HEAD..HEAD
   git diff FETCH_HEAD...HEAD
   ```

4. 同じbase repo・baseブランチ・headブランチのPR候補を取得し、`headRepository`と`headRepositoryOwner`も実際のhead repoと照合して、重複作成を避ける。`gh pr list --head`には`owner:branch`形式を渡さない。

   ```bash
   gh pr list --repo <base-repo> --base <base> --head <head-branch> \
     --json number,url,baseRefName,headRefName,headRepository,headRepositoryOwner
   ```

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

6. 未送信のコミットがあれば、[git-commit-push](../git-commit-push/SKILL.md)の許可条件と手順に従ってSSHでプッシュする。送信済みの場合も、実際の送信先URL・ブランチの`git ls-remote`のSHAがPR対象のHEADと一致することを確認する。URL指定プッシュではupstreamやリモート追跡参照の更新を前提にしない。

   PR作成には`--repo`でbase repo、`--base`でマージ先、`--head`で送信済みのブランチを明示し、CLIによる自動プッシュ・forkを避ける。`<head-selector>`は同じリポジトリなら`<head-branch>`、個人所有のforkなら`<head-owner>:<head-branch>`とする。組織所有のforkなど、この形式でhead repoを確定できない場合は推測で進めず確認する。呼び出し元にユーザー確認の手順があれば、それに従う。

   ```bash
   gh pr create \
     --repo <base-repo> \
     --base <base> \
     --head <head-selector> \
     --title "<title>" \
     --body-file <body-file>
   ```

7. 作成結果のbase repo・baseブランチ・head repo・headブランチが指定と一致することを確認し、PRのURLをユーザーに報告する。

## ルール

- PR作成依頼には、そのPRの作成に必要な対象ブランチのプッシュの許可を含める。得た許可を再確認しない。
- 未コミットの変更は勝手にコミットしない。
- PR本文には実際の変更内容のみ記載する。
- 実施していないテストを実施済みと記載しない。
- 強制PushやPRのマージは行わない。
- ユーザーが指定した場合のみDraft PRを作成する。

