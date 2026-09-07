#!/usr/bin/env bash
# One-time Telegram login for this checkout.
set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

env_val() {
  python3 - "$1" <<'PY'
import sys
from pathlib import Path
key = sys.argv[1]
for raw in Path(".env").read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, v = line.split("=", 1)
    if k == key:
        print(v.strip().strip('"').strip("'"))
        break
PY
}

TELEGRAM_API_ID="$(env_val TELEGRAM_API_ID)"
TELEGRAM_API_HASH="$(env_val TELEGRAM_API_HASH)"

if [[ -z "${TELEGRAM_API_ID}" || -z "${TELEGRAM_API_HASH}" ]]; then
  echo "先去 https://my.telegram.org/apps 创建应用，拿到 API ID 和 API Hash。"
  read -r -p "TELEGRAM_API_ID: " TELEGRAM_API_ID
  read -r -p "TELEGRAM_API_HASH: " TELEGRAM_API_HASH
  tmp="$(mktemp)"
  awk -v id="$TELEGRAM_API_ID" -v hash="$TELEGRAM_API_HASH" '
    /^TELEGRAM_API_ID=/ { print "TELEGRAM_API_ID=" id; next }
    /^TELEGRAM_API_HASH=/ { print "TELEGRAM_API_HASH=" hash; next }
    { print }
  ' .env >"$tmp"
  mv "$tmp" .env
  export TELEGRAM_API_ID TELEGRAM_API_HASH
fi

echo "接下来用 QR 登录（手机 Telegram > Settings > Devices > Link Desktop Device）"
echo "或 Ctrl+C 后执行: uv run session_string_generator.py --phone"
uv run session_string_generator.py --qr
