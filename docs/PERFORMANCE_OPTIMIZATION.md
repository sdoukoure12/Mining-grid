# Performance Optimization Guide

This document provides guidance on optimising the Mining Grid server for production workloads.

## Performance Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Hashrate | < 80 TH/s per active miner | < 50 TH/s |
| Temperature | ≥ 70 °C | ≥ 85 °C |
| API response time | > 500 ms | > 2000 ms |
| Memory usage | > 400 MB | > 500 MB |

## Environment Tuning

Add these variables to `/opt/mining-grid/.env` to tune performance thresholds:

```env
# Performance thresholds
HASHRATE_THRESHOLD=100     # Minimum total TH/s before warning
TEMP_WARNING=70            # Temperature warning (°C)
TEMP_CRITICAL=85           # Temperature critical (°C)

# Monitoring intervals
CHECK_INTERVAL_SECONDS=60  # Health check interval
ALERT_THRESHOLD=3          # Consecutive failures before recovery
```

## Running Performance Checks

```bash
# Standard output
bash /opt/mining-grid/scripts/performance-check.sh

# JSON output (for integration with monitoring tools)
bash /opt/mining-grid/scripts/performance-check.sh --json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All metrics within normal range |
| 1 | Warning threshold exceeded |
| 2 | Critical threshold exceeded |

## Node.js Tuning

Add to the `ExecStart` line in `systemd/mining-grid.service` for better memory management:

```ini
ExecStart=/usr/bin/node --max-old-space-size=384 server.js
```

## Docker Resource Limits

The `docker-compose.yml` includes memory and CPU limits. Adjust in `docker-compose.yml`:

```yaml
services:
  mining-grid:
    deploy:
      resources:
        limits:
          cpus: '0.80'
          memory: 512M
```

## Monitoring with GitHub Actions

The `performance-monitor.yml` workflow runs every 30 minutes and:

1. Fetches `/api/stats` from the server
2. Evaluates hashrate thresholds
3. Generates a step summary report visible in the Actions tab

Review the workflow run summaries at:  
`https://github.com/sdoukoure12/Mining-grid/actions/workflows/performance-monitor.yml`

## Log Analysis

```bash
# View recent performance logs
tail -100 /var/log/mining-grid/performance.log

# Watch live
tail -f /var/log/mining-grid/performance.log

# Find warnings
grep "⚠️" /var/log/mining-grid/performance.log

# Find critical events
grep "❌\|CRITICAL" /var/log/mining-grid/performance.log
```
