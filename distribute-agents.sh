#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./distribute-agents.sh [--dry-run] REPOSITORY [REPOSITORY ...]

Copy the shared AGENTS.md to each repository root.
  --dry-run   Check conflicts and print actions without changes.
  -h, --help  Show this help.
Existing files with different content are never overwritten.
EOF
}

dry_run=false
repositories=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    --) shift; repositories+=("$@"); break ;;
    -*) echo "Error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    *) repositories+=("$1") ;;
  esac
  shift
done

if [ "${#repositories[@]}" -eq 0 ]; then
  usage >&2
  exit 2
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_path="$repo_root/AGENTS.md"
destinations=()
conflicts=0

# Check every destination before copying any files.
for repository in "${repositories[@]}"; do
  if [ ! -d "$repository" ]; then
    echo "Error: repository directory does not exist: $repository" >&2
    conflicts=1
    continue
  fi
  repository="$(cd -- "$repository" && pwd -P)"
  if [ ! -d "$repository/.git" ] && [ ! -f "$repository/.git" ]; then
    echo "Error: not a Git repository root: $repository" >&2
    conflicts=1
    continue
  fi
  destination="$repository/AGENTS.md"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ ! -f "$destination" ] || [ -L "$destination" ] || ! cmp -s "$source_path" "$destination"; then
      echo "Conflict: existing destination differs: $destination" >&2
      conflicts=1
    fi
  fi
  destinations+=("$destination")
done

if [ "$conflicts" -ne 0 ]; then
  echo 'No files distributed. Review conflicting destinations before retrying.' >&2
  exit 1
fi

for destination in "${destinations[@]}"; do
  if [ -f "$destination" ] && [ ! -L "$destination" ] && cmp -s "$source_path" "$destination"; then
    echo "Unchanged: $destination"
  elif [ "$dry_run" = true ]; then
    echo "Would copy: $source_path -> $destination"
  else
    # Refuse to overwrite files created after the preflight check.
    (set -o noclobber; cat -- "$source_path" > "$destination")
    echo "Installed: $destination"
  fi
done
