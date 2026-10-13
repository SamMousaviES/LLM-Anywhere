#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN_ROOT="$ROOT/bin"
STABLE_URL="https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"

command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required." >&2; exit 1; }

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

install_asset() {
  local asset="$1"
  local destination="$2"
  local archive="$TMP_ROOT/$asset"
  local extract="$TMP_ROOT/extract-${destination##*/}"
  local server server_dir

  mkdir -p "$extract" "$destination"
  echo "Downloading $asset ..."
  curl --fail --location --retry 3 \
    "https://github.com/ggml-org/llama.cpp/releases/download/$BUILD_TAG/$asset" \
    --output "$archive"
  tar -xzf "$archive" -C "$extract"
  server="$(find "$extract" -type f -name llama-server -print -quit)"
  [[ -n "$server" ]] || { echo "llama-server was not found in $asset" >&2; exit 1; }
  server_dir="$(dirname "$server")"
  cp -R "$server_dir/." "$destination/"
  chmod +x "$destination"/llama* "$destination"/ggml* 2>/dev/null || true
  echo "Installed: $destination"
}

echo "Resolving the current stable llama.cpp build ..."
STABLE_JSON="$(curl --fail --silent --show-error --location \
  -H 'Accept: application/vnd.github+json' -H 'User-Agent: LLM-Anywhere-Setup' \
  "$STABLE_URL")"
POINTER_URL="$(printf '%s' "$STABLE_JSON" | tr ',' '\n' | sed -n \
  's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*nightly-tag.txt\)".*/\1/p' | head -n 1)"
[[ -n "$POINTER_URL" ]] || { echo "Could not resolve the stable llama.cpp build." >&2; exit 1; }
BUILD_TAG="$(curl --fail --silent --show-error --location "$POINTER_URL" | tr -d '\r\n')"
[[ "$BUILD_TAG" =~ ^b[0-9]+$ ]] || { echo "Unexpected llama.cpp build tag: $BUILD_TAG" >&2; exit 1; }

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    install_asset "llama-$BUILD_TAG-bin-macos-arm64.tar.gz" "$BIN_ROOT/mac-arm64"
    ;;
  Darwin-x86_64)
    install_asset "llama-$BUILD_TAG-bin-macos-x64.tar.gz" "$BIN_ROOT/mac-x64"
    ;;
  Linux-x86_64)
    install_asset "llama-$BUILD_TAG-bin-ubuntu-x64.tar.gz" "$BIN_ROOT/ubuntu-cpu-x64"
    install_asset "llama-$BUILD_TAG-bin-ubuntu-vulkan-x64.tar.gz" "$BIN_ROOT/ubuntu-vulkan-x64"
    ;;
  Linux-aarch64|Linux-arm64)
    install_asset "llama-$BUILD_TAG-bin-ubuntu-arm64.tar.gz" "$BIN_ROOT/ubuntu-cpu-arm64"
    ;;
  *)
    echo "Unsupported platform: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

mkdir -p "$ROOT/models"
echo
echo "Setup complete (llama.cpp $BUILD_TAG)."
echo "Next: add a GGUF file to models/, then run bash Start-Mac-or-Ubuntu.sh."
