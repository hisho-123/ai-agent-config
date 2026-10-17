#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-playwright.sh [--dry-run]

Register Playwright MCP in the Codex user configuration.
  --dry-run   Check dependencies and conflicts without downloading or registering.
  -h, --help  Show this help.
EOF
}

dry_run=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

for dependency in node npx codex; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    echo "Error: required command not found: $dependency" >&2
    exit 1
  fi
done
if ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)'; then
  echo 'Error: Node.js 18 or newer is required.' >&2
  exit 1
fi

mcp_args=(-y @playwright/mcp@latest --browser chrome --headless --isolated)

# プロジェクト側の設定を登録済みの共通設定と誤認しないよう、リポジトリ外で確認する。
cd /

server_state() {
  codex mcp list --json | node -e '
    let input = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", chunk => input += chunk);
    process.stdin.on("end", () => {
      try {
        const servers = JSON.parse(input);
        if (!Array.isArray(servers)) throw new Error("Expected a server list");
        const matches = servers.filter(server => server.name === "playwright");
        if (!matches.length) {
          console.log("missing");
          return;
        }
        const server = matches[0];
        const transport = server.transport || {};
        const expectedArgs = process.argv.slice(1);
        const same = matches.length === 1 && server.enabled === true &&
          !server.disabled_reason && transport.type === "stdio" &&
          transport.command === "npx" &&
          JSON.stringify(transport.args) === JSON.stringify(expectedArgs) &&
          Object.keys(transport.env || {}).length === 0 &&
          (transport.env_vars || []).length === 0 && transport.cwd == null &&
          server.enabled_tools == null &&
          (server.disabled_tools == null || server.disabled_tools.length === 0);
        console.log(same ? "matching" : "conflict");
      } catch (error) {
        console.error("Error: could not read the Codex MCP server list.");
        process.exitCode = 1;
      }
    });
  ' -- "${mcp_args[@]}"
}

check_existing() {
  local state
  if ! state="$(server_state)"; then
    echo 'No MCP configuration changed.' >&2
    exit 1
  fi
  case "$state" in
    matching) echo 'Unchanged: playwright MCP'; exit 0 ;;
    conflict)
      echo 'Conflict: existing playwright MCP configuration differs.' >&2
      echo 'No MCP configuration changed. Review with: codex mcp get playwright' >&2
      exit 1
      ;;
    missing) ;;
    *) echo 'Error: unexpected MCP configuration state.' >&2; exit 1 ;;
  esac
}

check_existing
if [ "$dry_run" = true ]; then
  echo 'Would download: npx -y @playwright/mcp@latest --version'
  echo "Would register: codex mcp add playwright -- npx ${mcp_args[*]}"
  exit 0
fi

# 初回起動時の取得待ちと、取得失敗による未準備のMCP登録を避ける。
npx -y @playwright/mcp@latest --version
# パッケージ取得中に追加された設定も上書きしない。
check_existing
codex mcp add playwright -- npx "${mcp_args[@]}"
echo 'Installed: playwright MCP (headless Chrome, isolated session)'
echo 'Restart Codex or reconnect MCP servers to load the new tools.'
