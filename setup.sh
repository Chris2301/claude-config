#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Link a project's .claude/ to the shared claude-config repo.
#
# Usage:
#   ~/codebranch/claude-config/setup.sh /path/to/project
#
# What it does:
#   1. Creates .claude/ in the target project if it doesn't exist
#   2. Symlinks agents/, skills/, commands/ to this repo
#   3. Leaves settings.local.json and other project-specific files untouched

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIRS=("agents" "skills" "commands")

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-path>"
  echo "Example: $0 ~/codebranch/my-other-project"
  exit 1
fi

PROJECT_DIR="$(cd "$1" && pwd)"
CLAUDE_DIR="${PROJECT_DIR}/.claude"

mkdir -p "$CLAUDE_DIR"

for dir in "${SHARED_DIRS[@]}"; do
  target="${CLAUDE_DIR}/${dir}"
  source="${SCRIPT_DIR}/${dir}"

  if [[ -L "$target" ]]; then
    echo "  [skip] ${dir}/ — symlink already exists"
  elif [[ -d "$target" ]]; then
    echo "  [WARN] ${dir}/ — directory exists and is NOT a symlink. Remove it manually if you want to link."
  else
    ln -s "$source" "$target"
    echo "  [link] ${dir}/ -> ${source}"
  fi
done

echo ""
echo "Done. Project ${PROJECT_DIR} is now linked to claude-config."
echo "Project-specific files (settings.local.json, etc.) are untouched."
