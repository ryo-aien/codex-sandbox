#!/usr/bin/env bash
set -euo pipefail

echo "[install-codex] Installing Codex..."

if [[ -n "${CODEX_INSTALL_CMD:-}" ]]; then
  eval "${CODEX_INSTALL_CMD}"
elif [[ -f "/workspace/bin/codex" ]]; then
  sudo install -m 0755 /workspace/bin/codex /usr/local/bin/codex
else
  cat <<'EOF' >&2
[install-codex] No installer configured.
Set CODEX_INSTALL_CMD or place an executable at /workspace/bin/codex.
EOF
  exit 1
fi

AUTH_FILE="${HOME}/.codex/auth.json"
if [[ -f "${AUTH_FILE}" && -w "${AUTH_FILE}" ]]; then
  chmod 0400 "${AUTH_FILE}"
  echo "[install-codex] Locked ${AUTH_FILE} (chmod 0400)."
fi

echo "[install-codex] Done."
