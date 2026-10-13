#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODELS="$ROOT/models"
PLLM_PORT="${PORTABLELLM_PORT:-8080}"
PLLM_CONTEXT="${PORTABLELLM_CONTEXT_SIZE:-4096}"
PLLM_BACKEND="${PORTABLELLM_BACKEND:-auto}"
[[ -d "$MODELS" ]] || { echo "Models folder missing: $MODELS"; exit 1; }
bash "$ROOT/Generate-Continue-Config.sh" "$MODELS" "$ROOT/continue-config.yaml" "$PLLM_PORT" || exit 1
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    RUNNER="$ROOT/bin/mac-arm64/llama-server"
    ARGS=(-ngl auto)
    ;;
  Darwin-x86_64)
    RUNNER="$ROOT/bin/mac-x64/llama-server"
    ARGS=(-ngl auto)
    ;;
  Linux-x86_64)
    GPU="$ROOT/bin/ubuntu-vulkan-x64/llama-server"
    CPU="$ROOT/bin/ubuntu-cpu-x64/llama-server"
    if [[ "$PLLM_BACKEND" != "cpu" && -x "$GPU" ]] &&
      "$GPU" --list-devices 2>&1 | grep -Eq 'Vulkan[0-9]'; then
      echo "Vulkan GPU found"
      RUNNER="$GPU"
      ARGS=(-ngl auto)
    else
      echo "Using CPU"
      RUNNER="$CPU"
      ARGS=(-ngl 0)
    fi
    ;;
  Linux-aarch64|Linux-arm64)
    RUNNER="$ROOT/bin/ubuntu-cpu-arm64/llama-server"
    ARGS=(-ngl 0)
    ;;
  *)
    echo "Unsupported system"
    exit 1
    ;;
esac
[[ -x "$RUNNER" ]] || {
  echo "llama.cpp runtime not found: $RUNNER" >&2
  echo "Run: bash Setup-Mac-or-Ubuntu.sh" >&2
  exit 1
}
echo "Multi-model mode: choose a model in the GUI"
echo "Open http://127.0.0.1:$PLLM_PORT"
echo "Continue setup: see $ROOT/docs/CONTINUE.md"
"$RUNNER" --models-dir "$MODELS" --models-max 1 --models-autoload -c "$PLLM_CONTEXT" "${ARGS[@]}" --host 127.0.0.1 --port "$PLLM_PORT"
