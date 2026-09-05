#!/usr/bin/env bash
set -euo pipefail

# Build a .plasmoid archive from metadata.json + contents/.
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f metadata.json ]]; then
  echo "Error: metadata.json not found in project root." >&2
  exit 1
fi

if [[ ! -d contents ]]; then
  echo "Error: contents/ directory not found in project root." >&2
  exit 1
fi

read_json_field() {
  local sed_expr="$1"
  sed -nE "$sed_expr" metadata.json | head -n1
}

PLUGIN_ID="$(read_json_field 's/.*"Id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
PLUGIN_VERSION="$(read_json_field 's/.*"Version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"

if [[ -z "$PLUGIN_ID" || -z "$PLUGIN_VERSION" ]]; then
  echo "Error: Could not parse KPlugin.Id and/or KPlugin.Version from metadata.json." >&2
  exit 1
fi

OUT_DIR="dist"
OUT_FILE="$OUT_DIR/${PLUGIN_ID}-${PLUGIN_VERSION}.plasmoid"

mkdir -p "$OUT_DIR"
rm -f "$OUT_FILE"

if command -v zip >/dev/null 2>&1; then
  # -X strips extra file attributes for reproducible archives across systems.
  zip -r -X "$OUT_FILE" metadata.json contents >/dev/null
else
  echo "Error: 'zip' is not available to build the archive." >&2
  exit 1
fi

echo "Built: $OUT_FILE"
