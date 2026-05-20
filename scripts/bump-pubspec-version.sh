#!/usr/bin/env bash
# Bump pubspec.yaml version to the given semver, incrementing the +buildNumber.
# Usage: bump-pubspec-version.sh <semver>
# Called by semantic-release via .releaserc.json prepareCmd.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <semver>" >&2
  exit 1
fi

VERSION="$1"
PUBSPEC="${PUBSPEC_PATH:-pubspec.yaml}"

if [[ ! -f "$PUBSPEC" ]]; then
  echo "❌  $PUBSPEC not found" >&2
  exit 1
fi

# Extract current build number (the +N suffix). Default to 0 if absent.
current_line="$(grep -E '^version:[[:space:]]+' "$PUBSPEC" | head -n1)"
if [[ -z "$current_line" ]]; then
  echo "❌  No 'version:' line in $PUBSPEC" >&2
  exit 1
fi

# Parse: 'version: X.Y.Z+N'  →  N (or empty)
current_build="$(echo "$current_line" \
  | sed -nE 's/^version:[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+(\+([0-9]+))?.*$/\2/p')"
if [[ -z "$current_build" ]]; then
  current_build=0
fi
new_build=$((current_build + 1))

new_line="version: ${VERSION}+${new_build}"

# Portable in-place sed (GNU + BSD).
if sed --version >/dev/null 2>&1; then
  sed -i -E "s|^version:[[:space:]]+.*|${new_line}|" "$PUBSPEC"
else
  sed -i '' -E "s|^version:[[:space:]]+.*|${new_line}|" "$PUBSPEC"
fi

echo "✅  Bumped pubspec.yaml → ${new_line}"
echo "   (was: ${current_line})"
