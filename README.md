# ai-agent-config

すべてのローカルリポジトリで使うCodexの共通指示、コマンド実行ルール、自作skills、Playwright MCPの導入手順をGitで管理します。

| 管理対象 | ソース | 配置先 | 配置方法 |
| --- | --- | --- | --- |
| 各リポジトリへ配布する共通指示 | `AGENTS.md` | 各リポジトリのルートの`AGENTS.md` | `distribute-agents.sh`でコピー |
| 行動・開発の共通指示 | `codex/AGENTS.md` | `~/.codex/AGENTS.md` | コピー |
| コマンド実行ルール | `codex/rules/shared.rules` | `~/.codex/rules/shared.rules` | コピー |
| 自作skills | `skills/<スキル名>/` | `~/.agents/skills/<スキル名>` | シンボリックリンク |
| Playwright MCP | `install-playwright.sh` | Codexのユーザー設定（通常は`~/.codex/config.toml`） | `codex mcp add`で登録 |

初期の共通指示は、日本語での回答、結論と根拠の簡潔な説明、変更内容と検証結果の報告です。
実行ルールはコメントのみで、初期状態では許可・禁止を追加しません。
自作skillsとして、明示的な指示がある場合のみコミット・SSHプッシュを行う[git-commit-push](skills/git-commit-push/SKILL.md)と、GitHub CLIでPRを作成する[github-pr-create](skills/github-pr-create/SKILL.md)を管理しています。

## 各リポジトリへのAGENTS.md配布

ルートの`AGENTS.md`が配布元です。初期状態は空ファイルで、今後、全リポジトリで共有したい指示を記載します。
`codex/AGENTS.md`とは別に管理します。

配布先のGitリポジトリのルートを指定します。複数指定できます。

```sh
./distribute-agents.sh --dry-run /path/to/repo-a /path/to/repo-b
./distribute-agents.sh /path/to/repo-a /path/to/repo-b
```

同じ内容のファイルはスキップします。異なる既存ファイルやリンクがある場合は、どの配布先にもコピーせず停止します。
配布元を更新した場合は、各リポジトリの既存の指示を確認・統合するか、バックアップとして移動してから再実行してください。
コピー後のファイルは各リポジトリでGit管理できます。配布先のコミットやプッシュは行いません。

## インストール

macOS/LinuxのBashで、cloneしたリポジトリのルートから実行します。

```sh
./install.sh --dry-run
./install.sh
```

dry-runは衝突を確認し、予定する配置を表示するだけで、ディレクトリも作成しません。
同じ内容のコピーや同じリンクはスキップします。異なるファイル、ディレクトリ、リンクがあれば、
配置を始める前に終了します。既存設定は内容を確認し、バックアップとして移動してから再実行してください。
自動の上書き・削除・バックアップは行いません。

`default.rules`など管理対象外のファイルには触れません。
`~/.codex/AGENTS.override.md`が存在すると通知します。非空のoverrideは共通の`AGENTS.md`より優先されます。

配置先は通常のホーム配下に固定しています。`CODEX_HOME`を変更している環境では、その配置先へ別途適用してください。
検証用に`./install.sh --target-home /path/to/temporary-home`で別のホームを指定できます。

リンクはclone先の絶対パスを参照します。インストール後にclone先を移動した場合は、古いリンクを確認・削除し、再配置してください。

## Playwright MCPの導入

Codexにブラウザでの動作確認を依頼するための共通環境です。`install.sh`とは別に、必要なPCで一度実行します。
Node.js 18以上、`npx`、Codex CLI、Google Chromeが必要です。
Chromeが未導入の場合は、[公式サイト](https://www.google.com/chrome/)からインストールするか、
`npx -y playwright@latest install chrome`で用意してください。Linuxでは追加のOS依存パッケージが必要になる場合があります。

```sh
./install-playwright.sh --dry-run
./install-playwright.sh
codex mcp get playwright
```

dry-runでは依存コマンドと設定の衝突だけを確認し、ダウンロードや設定変更は行いません。
通常実行ではパッケージを事前取得してから、以下の構成をCodex CLIで登録します。

```sh
codex mcp add playwright -- npx -y @playwright/mcp@latest \
  --browser chrome --headless --isolated
```

Chromeは画面を表示せずに動作し、ブラウザを閉じるとログイン状態がリセットされます。
普段使うChromeのログイン状態は引き継ぎません。同じMCPセッション内では状態が維持されます。
パッケージは`@latest`を使用するため、起動時にnpmの最新バージョンが取得されることがあります。

既存の`playwright`が同じコマンド・引数で有効になっており、追加の実行環境やツール制限がなければスキップします。
異なる設定があれば、上書きせず停止します。`codex mcp get playwright`で確認し、
置き換える場合は`codex mcp remove playwright`を実行してから再導入してください。
既存のモデル設定やほかのMCPは変更しません。`CODEX_HOME`を設定している場合はCodex CLIが選ぶユーザー設定に登録されます。
プロジェクト固有の`.codex/config.toml`がある場合は、その設定が優先されることがあります。

登録後はCodexを再起動するか、MCPサーバーを再接続します。CLIでは`/mcp`、アプリではMCPサーバー設定で接続を確認できます。
確認対象のプロジェクトでアプリを起動し、例えば次のように依頼します。

```text
Playwright MCPを使い、http://localhost:3000 の画面遷移とフォーム送信を確認してください。
正常系と入力エラーを確認し、期待結果・実際の結果・スクリーンショットの保存先を報告してください。
確認が終わったらテスト用ブラウザを閉じてください。
```

対象URL、確認したい操作、期待する結果を指定してください。ログインが必要な場合はテスト用アカウントを用意します。
認証情報やスクリーンショットなどの確認結果は、この設定リポジトリに取り込みません。
アプリへのPlaywright Test導入やCIでの定期実行は、対象プロジェクトで別途設定します。

取り外す場合は次を実行し、Codexを再接続します。npmキャッシュやChromeは削除しません。

```sh
codex mcp remove playwright
```

導入スクリプトの回帰テストは`bash tests/install-playwright.sh`で実行できます。
テストではCLIを置き換え、実際のユーザー設定やネットワークへアクセスせずに検証します。

## 更新と取り外し

1. このリポジトリで設定を編集・レビューし、Git管理します。他のPCでは`git pull --ff-only`で更新します。
2. skillsの既存ファイルの変更はリンク先に反映されます。skillsを追加した場合はスクリプトを再実行します。
3. コピーした共通指示・実行ルールが変わると再実行時に衝突します。配置済みファイルを確認・バックアップとして移動してから再実行します。
4. 実行ルールの変更後はCodexを再起動します。共通指示も新しいセッションで確認します。skillsの変更が表示されない場合は再起動します。

共通指示・実行ルール・skillsの取り外しや改名では、表にある各配置先を確認して手動で取り除きます。
スクリプトは古いリンクを自動削除しません。
Playwright MCPは前述の`codex mcp remove playwright`で取り外します。

## 設定の使い分け

- 共通の応答・作業方針は`codex/AGENTS.md`に記載します。
- プロジェクト固有の開発手順は、各リポジトリの`AGENTS.md`に記載します。共通指示に加えて読み込まれ、より具体的な指示が優先されます。
- コマンド実行の許可・承認要求・禁止は`.rules`で設定します。自然言語の作業指示とは用途が異なります。
- Codexが許可リストに追記する`default.rules`から共有したいルールだけを、レビューして`shared.rules`に取り込みます。
- 自作の汎用skillsの追加方法は[skills/README.md](skills/README.md)を参照してください。プロジェクト専用skillsは各リポジトリの`.agents/skills/`で管理します。
- 組み込み・プラグインのスキル、認証情報、ローカルの履歴・キャッシュは取り込みません。

ルールが複数一致すると最も制限の強い判定が使われます。追加したルールは、Codex CLIがある環境で次のように確認できます。

```sh
codex execpolicy check --pretty --rules codex/rules/shared.rules -- gh pr view 123
```

## 公式ドキュメント

- [Skills](https://learn.chatgpt.com/docs/build-skills)
- [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [コマンド実行ルール](https://learn.chatgpt.com/docs/agent-configuration/rules)
- [CodexのMCP設定](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
