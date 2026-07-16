#!/usr/bin/env bash
# Checks the funded balance of a Marinade institutional (SelectStake) bond
# account and sends a Telegram alert when it drops below MIN_BALANCE_SOL.
set -uo pipefail

: "${BOND_ADDRESS:?BOND_ADDRESS is required}"
: "${MIN_BALANCE_SOL:?MIN_BALANCE_SOL is required}"
: "${RPC_URL:?RPC_URL is required}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

alert() {
  local msg="$1"
  log "ALERT: $msg"
  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    if ! curl -sf -H 'Content-Type: application/json' \
      -d "$(jq -n --arg chat "$TELEGRAM_CHAT_ID" \
              --arg text "🚨 marinade-select-monitoring
$msg" '{chat_id: $chat, text: $text}')" \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null; then
      log "ERROR: failed to deliver Telegram alert"
    fi
  else
    log "WARN: TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID not set, alert only logged"
  fi
}

# Parse stdout only: the CLI writes warnings (e.g. "bigint: Failed to load
# bindings") to stderr, which would corrupt the JSON.
stderr_file="$(mktemp)"
trap 'rm -f "$stderr_file"' EXIT
if ! output="$(validator-bonds-institutional show-bond "$BOND_ADDRESS" \
  --with-funding -u "$RPC_URL" -f json 2>"$stderr_file")"; then
  errors="$(cat "$stderr_file")"
  alert "bond check failed for $BOND_ADDRESS:
${errors:0:1500}"
  exit 1
fi

# The CLI prints amounts as formatted strings (e.g. "12.345 SOLs"),
# so strip everything but the leading number.
amount_active="$(jq -r '.amountActive' <<<"$output" | grep -oE '^[0-9]+(\.[0-9]+)?' || true)"

if [[ -z "$amount_active" ]]; then
  alert "could not parse amountActive from show-bond output:
${output:0:1500}"
  exit 1
fi

log "bond $BOND_ADDRESS amountActive=$amount_active SOL (min=$MIN_BALANCE_SOL SOL)"

if awk -v a="$amount_active" -v m="$MIN_BALANCE_SOL" 'BEGIN { exit !(a < m) }'; then
  alert "bond $BOND_ADDRESS is underfunded: $amount_active SOL < $MIN_BALANCE_SOL SOL minimum. Top it up with fund-bond-sol."
  exit 2
fi

log "OK"
