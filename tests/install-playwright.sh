#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
task_temp="$(mktemp -d)"
trap 'rm -rf -- "$task_temp"' EXIT
mkdir "$task_temp/bin"
export PLAYWRIGHT_INSTALL_TEST_DIR="$task_temp"

# 実際のユーザー設定やネットワークへ触れず、CLIとの境界で副作用を検証する。
cat > "$task_temp/bin/codex" <<'EOF'
#!/usr/bin/env node
const fs = require('node:fs');
const dir = process.env.PLAYWRIGHT_INSTALL_TEST_DIR;
const args = process.argv.slice(2);
if (process.cwd() !== '/') throw new Error('Project settings must not be loaded');
const config = JSON.parse(fs.readFileSync(`${dir}/config.json`, 'utf8'));
if (args.join(' ') === 'mcp list --json') {
  if (fs.existsSync(`${dir}/fail-list`)) process.exit(1);
  console.log(JSON.stringify(config.servers));
} else if (args.slice(0, 4).join(' ') === 'mcp add playwright --') {
  fs.appendFileSync(`${dir}/add.log`, 'add\n');
  config.servers.push({
    name: 'playwright', enabled: true,
    transport: { type: 'stdio', command: args[4], args: args.slice(5) }
  });
  fs.writeFileSync(`${dir}/config.json`, JSON.stringify(config));
} else {
  throw new Error(`Unexpected command: ${args.join(' ')}`);
}
EOF

cat > "$task_temp/bin/npx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$*" = '-y @playwright/mcp@latest --version' ]
echo download >> "$PLAYWRIGHT_INSTALL_TEST_DIR/npx.log"
if [ -f "$PLAYWRIGHT_INSTALL_TEST_DIR/fail-download" ]; then exit 1; fi
if [ -f "$PLAYWRIGHT_INSTALL_TEST_DIR/race-config.json" ]; then
  cp "$PLAYWRIGHT_INSTALL_TEST_DIR/race-config.json" "$PLAYWRIGHT_INSTALL_TEST_DIR/config.json"
fi
echo 'Version test'
EOF
chmod +x "$task_temp/bin/codex" "$task_temp/bin/npx"
export PATH="$task_temp/bin:$PATH"

cat > "$task_temp/config.json" <<'EOF'
{"model":"existing-model","servers":[{"name":"existing-mcp","enabled":true,"transport":{"type":"stdio","command":"existing-command"}}]}
EOF
cp "$task_temp/config.json" "$task_temp/initial.json"

expect_failure() {
  if bash "$repo_root/install-playwright.sh" "$@" > "$task_temp/output" 2>&1; then
    echo 'FAIL: expected the installer to stop.' >&2
    exit 1
  fi
}

bash "$repo_root/install-playwright.sh" --dry-run > "$task_temp/output"
cmp "$task_temp/initial.json" "$task_temp/config.json"
[ ! -e "$task_temp/npx.log" ] && [ ! -e "$task_temp/add.log" ]
echo 'PASS: dry-run changes no configuration and downloads nothing'

bash "$repo_root/install-playwright.sh" > "$task_temp/output"
node -e '
  const fs = require("node:fs");
  const assert = require("node:assert/strict");
  const dir = process.env.PLAYWRIGHT_INSTALL_TEST_DIR;
  const before = JSON.parse(fs.readFileSync(`${dir}/initial.json`));
  const after = JSON.parse(fs.readFileSync(`${dir}/config.json`));
  const server = after.servers.pop();
  assert.deepEqual(after, before);
  assert.deepEqual(server, {
    name: "playwright", enabled: true,
    transport: { type: "stdio", command: "npx", args: [
      "-y", "@playwright/mcp@latest", "--browser", "chrome", "--headless", "--isolated"
    ] }
  });
'
cp "$task_temp/config.json" "$task_temp/matching.json"
rm "$task_temp/npx.log" "$task_temp/add.log"
echo 'PASS: registration preserves existing settings and uses the expected arguments'

bash "$repo_root/install-playwright.sh" > "$task_temp/output"
cmp "$task_temp/matching.json" "$task_temp/config.json"
[ ! -e "$task_temp/npx.log" ] && [ ! -e "$task_temp/add.log" ]
echo 'PASS: repeated installation skips downloading and registration'

for conflict in args disabled env cwd tools; do
  node -e '
    const fs = require("node:fs");
    const dir = process.env.PLAYWRIGHT_INSTALL_TEST_DIR;
    const config = JSON.parse(fs.readFileSync(`${dir}/matching.json`));
    const server = config.servers[1];
    switch (process.argv[1]) {
      case "args": server.transport.args.pop(); break;
      case "disabled": server.enabled = false; break;
      case "env": server.transport.env = { TEST: "custom" }; break;
      case "cwd": server.transport.cwd = "/custom"; break;
      case "tools": server.enabled_tools = ["browser_snapshot"]; break;
    }
    fs.writeFileSync(`${dir}/config.json`, JSON.stringify(config));
  ' "$conflict"
  cp "$task_temp/config.json" "$task_temp/before.json"
  expect_failure
  cmp "$task_temp/before.json" "$task_temp/config.json"
  [ ! -e "$task_temp/npx.log" ] && [ ! -e "$task_temp/add.log" ]
done
echo 'PASS: conflicting arguments, disabled servers, environment, cwd and tool restrictions are preserved'

cp "$task_temp/initial.json" "$task_temp/config.json"
touch "$task_temp/fail-list"
expect_failure
cmp "$task_temp/initial.json" "$task_temp/config.json"
[ ! -e "$task_temp/npx.log" ] && [ ! -e "$task_temp/add.log" ]
rm "$task_temp/fail-list"
echo 'PASS: failed configuration inspection never triggers registration'

touch "$task_temp/fail-download"
expect_failure
cmp "$task_temp/initial.json" "$task_temp/config.json"
[ ! -e "$task_temp/add.log" ]
rm "$task_temp/fail-download" "$task_temp/npx.log"
echo 'PASS: failed downloads leave configuration unchanged'

# 取得処理を挟んだ再確認で、別操作によって追加された設定の上書きを防ぐ。
cp "$task_temp/before.json" "$task_temp/race-config.json"
expect_failure
cmp "$task_temp/race-config.json" "$task_temp/config.json"
[ ! -e "$task_temp/add.log" ]
echo 'PASS: configuration added during download is not overwritten'

expect_failure --unknown
echo 'PASS: unknown options are rejected'
