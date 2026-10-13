#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/models"
: > "$TMP_ROOT/models/alpha.gguf"
: > "$TMP_ROOT/models/model \"beta\".GGUF"

bash "$ROOT/Generate-Continue-Config.sh" \
  "$TMP_ROOT/models" "$TMP_ROOT/continue-config.yaml" 9090

grep -Fq 'name: Portable AI Models' "$TMP_ROOT/continue-config.yaml"
grep -Fq 'provider: llama.cpp' "$TMP_ROOT/continue-config.yaml"
grep -Fq 'model: "alpha"' "$TMP_ROOT/continue-config.yaml"
grep -Fq 'model: "model \"beta\""' "$TMP_ROOT/continue-config.yaml"
grep -Fq 'apiBase: "http://127.0.0.1:9090"' "$TMP_ROOT/continue-config.yaml"

if bash "$ROOT/Generate-Continue-Config.sh" \
  "$TMP_ROOT/models" "$TMP_ROOT/invalid.yaml" 70000 >/dev/null 2>&1; then
  echo "Invalid port test did not fail." >&2
  exit 1
fi

echo "Bash generator tests passed."
