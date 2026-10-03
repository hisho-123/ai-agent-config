#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--target-home DIRECTORY]

Copy shared Codex instructions and rules, and link individual skills.
  --dry-run                Check conflicts and print actions without changes.
  --target-home DIRECTORY   Use an alternate home directory (for verification).
  -h, --help               Show this help.
EOF
}

dry_run=false
target_home="${HOME:?HOME must be set}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    --target-home)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo 'Error: --target-home requires a directory.' >&2
        exit 2
      fi
      target_home="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$target_home" in
  /*) ;;
  *) target_home="$PWD/$target_home" ;;
esac
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

sources=("$repo_root/codex/AGENTS.md" "$repo_root/codex/rules/shared.rules")
destinations=("$target_home/.codex/AGENTS.md" "$target_home/.codex/rules/shared.rules")
kinds=(copy copy)
actions=()
conflicts=0

# Inventory everything before creating directories or installing any files.
shopt -s nullglob dotglob
for skill in "$repo_root"/skills/*; do
  [ -d "$skill" ] || continue
  if [ ! -f "$skill/SKILL.md" ]; then
    echo "Error: missing SKILL.md: $skill" >&2
    conflicts=1
    continue
  fi
  sources+=("$skill")
  destinations+=("$target_home/.agents/skills/${skill##*/}")
  kinds+=(link)
done

for ((i=0; i<${#sources[@]}; i++)); do
  source_path="${sources[$i]}"
  destination="${destinations[$i]}"
  kind="${kinds[$i]}"
  action=install

  if [ "$kind" = copy ] && [ ! -f "$source_path" ]; then
    echo "Error: missing source file: $source_path" >&2
    conflicts=1
  fi

  parent="$(dirname -- "$destination")"
  while [ "$parent" != / ]; do
    if { [ -e "$parent" ] || [ -L "$parent" ]; } && [ ! -d "$parent" ]; then
      echo "Conflict: parent is not a directory: $parent" >&2
      conflicts=1
      break
    fi
    parent="$(dirname -- "$parent")"
  done

  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ "$kind" = copy ] && [ -f "$destination" ] && [ ! -L "$destination" ] && cmp -s "$source_path" "$destination"; then
      action=skip
    elif [ "$kind" = link ] && [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
      action=skip
    else
      echo "Conflict: existing destination differs: $destination" >&2
      conflicts=1
    fi
  fi
  actions+=("$action")
done

if [ -e "$target_home/.codex/AGENTS.override.md" ] || [ -L "$target_home/.codex/AGENTS.override.md" ]; then
  echo "Notice: AGENTS.override.md exists; a non-empty override takes precedence over AGENTS.md."
fi

if [ "$conflicts" -ne 0 ]; then
  echo 'No files installed. Review and move conflicting destinations before retrying.' >&2
  exit 1
fi

for ((i=0; i<${#sources[@]}; i++)); do
  source_path="${sources[$i]}"
  destination="${destinations[$i]}"
  if [ "${actions[$i]}" = skip ]; then
    echo "Unchanged: $destination"
    continue
  fi
  if [ "$dry_run" = true ]; then
    echo "Would ${kinds[$i]}: $source_path -> $destination"
    continue
  fi
  mkdir -p -- "$(dirname -- "$destination")"
  # Do not overwrite destinations created after the preflight check.
  if [ "${kinds[$i]}" = copy ]; then
    (set -o noclobber; cat -- "$source_path" > "$destination")
  else
    ln -s -- "$source_path" "$destination"
  fi
  echo "Installed: $destination"
done
