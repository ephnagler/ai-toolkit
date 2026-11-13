#!/usr/bin/env bash
# Symlink every skill folder in a synced repo into the folder your agent reads skills from.
# Idempotent. Never overwrites a real folder at the destination.
#
#   link-skills.sh [SOURCE_DIR]
#
# SOURCE_DIR defaults to $SKILLS_SRC. DEST defaults to ~/.claude/skills (set $SKILLS_DEST for other agents).
set -euo pipefail

SRC_DIR="${1:-${SKILLS_SRC:-}}"
DEST_DIR="${SKILLS_DEST:-$HOME/.claude/skills}"
if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
  echo "usage: link-skills.sh <folder of skills>   (or set SKILLS_SRC)" >&2
  exit 1
fi
SRC_DIR="$(cd "$SRC_DIR" && pwd)"
mkdir -p "$DEST_DIR"

linked=0 relinked=0 skipped=0
for dir in "$SRC_DIR"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  src="$SRC_DIR/$name"
  dest="$DEST_DIR/$name"
  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"; echo "relinked  $name"; relinked=$((relinked+1))
  elif [ -e "$dest" ]; then
    echo "SKIP      $name: a real folder exists at $dest; move it, then run again" >&2
    skipped=$((skipped+1))
  else
    ln -s "$src" "$dest"; echo "linked    $name"; linked=$((linked+1))
  fi
done

echo "---"
echo "linked $linked, relinked $relinked, skipped $skipped"
echo "Start a new agent session so newly linked skills load."
