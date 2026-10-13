#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
MODELS_DIR="${1:-$ROOT/models}"
OUTPUT_FILE="${2:-$ROOT/continue-config.yaml}"
SERVER_PORT="${3:-8080}"

case "$SERVER_PORT" in
  ''|*[!0-9]*) echo "Invalid port: $SERVER_PORT" >&2; exit 1 ;;
esac
if (( SERVER_PORT < 1 || SERVER_PORT > 65535 )); then
  echo "Invalid port: $SERVER_PORT" >&2
  exit 1
fi

shopt -s nullglob
MODEL_FILES=("$MODELS_DIR"/*.gguf "$MODELS_DIR"/*.GGUF)
if (( ${#MODEL_FILES[@]} == 0 )); then
  echo "No GGUF models found in: $MODELS_DIR" >&2
  exit 1
fi

TEMP_FILE="${OUTPUT_FILE}.tmp"
{
  echo 'name: LLM Anywhere'
  echo 'version: 1.0.0'
  echo 'schema: v1'
  echo
  echo 'models:'
  while IFS= read -r MODEL_FILE; do
    MODEL_ID="$(basename "$MODEL_FILE")"
    MODEL_ID="${MODEL_ID%.*}"
    YAML_ID="${MODEL_ID//\\/\\\\}"
    YAML_ID="${YAML_ID//\"/\\\"}"
    echo "  - name: \"${YAML_ID} (local)\""
    echo '    provider: llama.cpp'
    echo "    model: \"${YAML_ID}\""
    echo "    apiBase: \"http://127.0.0.1:${SERVER_PORT}\""
    echo '    roles:'
    echo '      - chat'
    echo '      - edit'
    echo '      - apply'
    echo
  done < <(printf '%s\n' "${MODEL_FILES[@]}" | LC_ALL=C sort -u)
} > "$TEMP_FILE"
mv -f "$TEMP_FILE" "$OUTPUT_FILE"

echo "Generated Continue config: $OUTPUT_FILE"
echo "Models included: ${#MODEL_FILES[@]}"
