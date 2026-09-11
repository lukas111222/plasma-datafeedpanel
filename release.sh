#!/usr/bin/env bash
set -euo pipefail

# Create a release artifact by bumping version (or not), building bundle, and writing SHA256.
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage:
  ./release.sh
  ./release.sh --no-bump
  ./release.sh --set-version X.Y.Z

Options:
  --no-bump           Keep current metadata version and only build + checksum.
  --set-version VER   Set metadata version to VER (expects numeric X.Y.Z).
  -h, --help          Show this help.
EOF
}

NO_BUMP=false
SET_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-bump)
      NO_BUMP=true
      shift
      ;;
    --set-version)
      if [[ $# -lt 2 ]]; then
        echo "Error: --set-version requires a value." >&2
        usage
        exit 1
      fi
      SET_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'." >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$NO_BUMP" == true && -n "$SET_VERSION" ]]; then
  echo "Error: --no-bump and --set-version cannot be used together." >&2
  exit 1
fi

if [[ ! -f metadata.json ]]; then
  echo "Error: metadata.json not found in project root." >&2
  exit 1
fi

ORIGINAL_METADATA="$(mktemp)"
RELEASE_SUCCEEDED=false
cp metadata.json "$ORIGINAL_METADATA"

cleanup() {
  if [[ "$RELEASE_SUCCEEDED" != true ]]; then
    cp "$ORIGINAL_METADATA" metadata.json
  fi
  rm -f "$ORIGINAL_METADATA"
}

trap cleanup EXIT

if [[ ! -x ./build.sh ]]; then
  chmod +x ./build.sh
fi

CURRENT_VERSION="$(sed -nE 's/.*"Version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' metadata.json | head -n1)"
if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Error: Could not parse KPlugin.Version from metadata.json." >&2
  exit 1
fi

validate_version() {
  local version="$1"
  IFS='.' read -r major minor patch <<< "$version"
  if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
    return 1
  fi
  if [[ ! "$major" =~ ^[0-9]+$ || ! "$minor" =~ ^[0-9]+$ || ! "$patch" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  return 0
}

if ! validate_version "$CURRENT_VERSION"; then
  echo "Error: Version '$CURRENT_VERSION' is not numeric X.Y.Z." >&2
  exit 1
fi

TARGET_VERSION="$CURRENT_VERSION"

if [[ -n "$SET_VERSION" ]]; then
  if ! validate_version "$SET_VERSION"; then
    echo "Error: --set-version expects numeric X.Y.Z, got '$SET_VERSION'." >&2
    exit 1
  fi
  TARGET_VERSION="$SET_VERSION"
  if [[ "$TARGET_VERSION" != "$CURRENT_VERSION" ]]; then
    sed -i -E "0,/\"Version\"[[:space:]]*:[[:space:]]*\"[^\"]+\"/s//\"Version\": \"$TARGET_VERSION\"/" metadata.json
    echo "Version set: $CURRENT_VERSION -> $TARGET_VERSION"
  else
    echo "Version unchanged: $CURRENT_VERSION"
  fi
elif [[ "$NO_BUMP" == true ]]; then
  echo "Version unchanged (--no-bump): $CURRENT_VERSION"
else
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
  TARGET_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
  sed -i -E "0,/\"Version\"[[:space:]]*:[[:space:]]*\"[^\"]+\"/s//\"Version\": \"$TARGET_VERSION\"/" metadata.json
  echo "Version bumped: $CURRENT_VERSION -> $TARGET_VERSION"
fi

./build.sh

PLUGIN_ID="$(sed -nE 's/.*"Id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' metadata.json | head -n1)"
ARTIFACT="dist/${PLUGIN_ID}-${TARGET_VERSION}.plasmoid"
CHECKSUM_FILE="${ARTIFACT}.sha256"

if [[ ! -f "$ARTIFACT" ]]; then
  echo "Error: Expected artifact not found: $ARTIFACT" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  (
    cd dist
    sha256sum "$(basename "$ARTIFACT")" > "$(basename "$CHECKSUM_FILE")"
  )
elif command -v shasum >/dev/null 2>&1; then
  (
    cd dist
    shasum -a 256 "$(basename "$ARTIFACT")" > "$(basename "$CHECKSUM_FILE")"
  )
else
  echo "Error: Missing checksum tool. Install 'sha256sum' (coreutils) or 'shasum'." >&2
  exit 1
fi

RELEASE_SUCCEEDED=true
echo "Release artifact: $ARTIFACT"
echo "Checksum file:   $CHECKSUM_FILE"
