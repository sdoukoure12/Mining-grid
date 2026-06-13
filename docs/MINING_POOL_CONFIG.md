# Mining Pool Configuration

This document describes how to configure mining pool connections for the Mining Grid server.

## Supported Mining Pools

The Mining Grid server supports connectivity checks to the following pools:

| Pool | Host | Port | Algorithm |
|------|------|------|-----------|
| Foundry USA | `pool.foundryusapool.com` | 3333 | SHA256 |
| AntPool | `ss.antpool.com` | 3333 | SHA256 |
| ViaBTC | `mining.viabtc.com` | 3333 | SHA256 |
| F2Pool | `btc.f2pool.com` | 3333 | SHA256 |
| SpiderPool | `btc.spiderpool.com` | 3333 | SHA256 |

## Environment Configuration

Add pool settings to your `/opt/mining-grid/.env` file:

```env
# Primary pool
POOL_PRIMARY_HOST=pool.foundryusapool.com
POOL_PRIMARY_PORT=3333

# Failover pool
POOL_FAILOVER_HOST=ss.antpool.com
POOL_FAILOVER_PORT=3333

# Health check settings
POOL_CHECK_INTERVAL=900    # seconds (15 min)
POOL_CONNECT_TIMEOUT=5     # seconds
```

## Health Check Behaviour

The `game-health-check.sh` script verifies pool connectivity every cycle. If all configured pools are unreachable, the script:

1. Logs a warning entry to `/var/log/mining-grid/health-check.log`
2. Increments the failure counter
3. Triggers `mining-recovery.sh` once the threshold (`ALERT_THRESHOLD`) is reached

## Adding a Custom Pool

Edit `scripts/game-health-check.sh` and add your pool to the `pools` array:

```bash
local pools=(
  "pool.foundryusapool.com:3333"
  "ss.antpool.com:3333"
  "your-custom-pool.example.com:3333"   # ← add here
)
```

## Pool Failover Logic

The server automatically selects the next available pool when the primary is unreachable. Failover is logged and can be monitored via:

```bash
tail -f /var/log/mining-grid/health-check.log | grep "Pool"
```
