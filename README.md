# marinade-select-monitoring

Read-only monitoring for a Marinade institutional (SelectStake) validator bond
account. Every 4 hours (configurable) it runs
`validator-bonds-institutional show-bond` and sends a Telegram alert if the
bond's active funded balance drops below a minimum threshold, or if the check
itself fails.

It never signs or sends transactions — topping up the bond
(`fund-bond-sol`) stays a manual operation.

## Topping up the bond

When the alert fires, fund the bond manually with the
[institutional CLI](https://github.com/marinade-finance/validator-bonds/tree/main/packages/validator-bonds-cli-institutional):

```bash
validator-bonds-institutional fund-bond-sol <vote-account-address> \
  --from <wallet-keypair> \
  --amount <SOL> \
  -u <rpc-url>
```

Marinade recommends keeping the bond funded at ~1 SOL per 1,000 SOL staked.

## Image

The GHCR package is private — build the image yourself:

```bash
docker build -t marinade-select-monitoring .
```

## Configuration

| Env var | Required | Default | Description |
|---|---|---|---|
| `BOND_ADDRESS` | yes | — | Bond account public key |
| `MIN_BALANCE_SOL` | yes | — | Alert when `amountActive` is below this (SOL) |
| `RPC_URL` | yes | — | Solana RPC endpoint |
| `TELEGRAM_BOT_TOKEN` | no | — | Telegram bot token; alerts are only logged if unset |
| `TELEGRAM_CHAT_ID` | no | — | Telegram chat id to send alerts to |
| `CHECK_INTERVAL_SECONDS` | no | `14400` | Seconds between checks (4h) |

## Usage

One-off check:

```bash
docker run --rm \
  -e BOND_ADDRESS=Gvt8s5Bwnhg4G27VbnT1Zkfh7Jsztq6CNvZcc5anPonS \
  -e MIN_BALANCE_SOL=10 \
  -e RPC_URL=https://api.mainnet-beta.solana.com \
  --entrypoint check.sh \
  marinade-select-monitoring
```

### docker compose

```yaml
services:
  marinade-select-monitoring:
    image: marinade-select-monitoring
    restart: unless-stopped
    environment:
      BOND_ADDRESS: Gvt8s5Bwnhg4G27VbnT1Zkfh7Jsztq6CNvZcc5anPonS
      MIN_BALANCE_SOL: "10"
      RPC_URL: ${RPC_URL}
      TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN}
      TELEGRAM_CHAT_ID: ${TELEGRAM_CHAT_ID}
```

## Exit codes (`check.sh`)

- `0` — bond balance is above the threshold
- `1` — check failed (RPC/CLI error, unparseable output); an alert is sent
- `2` — bond is underfunded; an alert is sent

## Notes

- The threshold compares against `amountActive` from
  `show-bond --with-funding`. Verify against your bond's actual JSON output
  that this is the field you care about (vs. `amountAtSettlements`,
  `amountToWithdraw`).
- The CLI formats amounts as strings (e.g. `"12.345 SOLs"`); `check.sh`
  strips the unit before comparing.
- CLI documentation:
  [@marinade.finance/validator-bonds-cli-institutional](https://github.com/marinade-finance/validator-bonds/tree/main/packages/validator-bonds-cli-institutional)
