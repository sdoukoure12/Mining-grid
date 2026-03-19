# Mining-Grid AUTOSTART Setup Guide

## Overview

This document describes the AUTOSTART infrastructure for the **Mining-Grid** game mining pool service. It covers automatic service startup, health monitoring, crash recovery, and resource management.

---

## Architecture

```
Mining-Grid AUTOSTART
├── GitHub Actions Workflows
│   ├── autostart-health-check.yml   – Hourly health monitoring
│   └── auto-recovery.yml            – Automated crash recovery
│
├── Systemd Services (Linux)
│   ├── mining-grid.service          – Main service (auto-restart)
│   ├── mining-grid-monitor.service  – Health monitor (oneshot)
│   └── mining-grid.timer            – Hourly timer trigger
│
├── Scripts
│   ├── scripts/health-check.sh      – Health verification
│   ├── scripts/recovery.sh          – Full service recovery
│   └── scripts/restart-handler.sh  – Graceful restart with hooks
│
├── Cron
│   └── cron/recovery-monitor.sh     – 15-minute crash detection
│
├── Docker
│   ├── docker-compose.yml           – Container auto-restart
│   └── Dockerfile                   – Production image
│
└── docs/
    └── AUTOSTART_SETUP.md           – This file
```

---

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# 1. Clone and enter the repository
git clone https://github.com/sdoukoure12/Mining-grid.git
cd Mining-grid

# 2. Copy and configure environment
cp .env.example .env   # or edit .env directly
nano .env

# 3. Start all services (with auto-restart)
docker compose up -d

# 4. Check status
docker compose ps
docker logs mining-grid -f
```

### Option 2: Systemd (Linux server)

```bash
# 1. Copy files to server
git clone https://github.com/sdoukoure12/Mining-grid.git /opt/mining-grid
cd /opt/mining-grid

# 2. Install dependencies
npm ci

# 3. Create service user
sudo useradd -r -s /bin/false mining-grid
sudo chown -R mining-grid:mining-grid /opt/mining-grid

# 4. Install systemd services
sudo cp systemd/mining-grid.service          /etc/systemd/system/
sudo cp systemd/mining-grid-monitor.service  /etc/systemd/system/
sudo cp systemd/mining-grid.timer            /etc/systemd/system/

# 5. Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now mining-grid.service
sudo systemctl enable --now mining-grid.timer

# 6. Verify
sudo systemctl status mining-grid
sudo systemctl list-timers mining-grid.timer
```

### Option 3: Cron (any Linux/macOS)

```bash
# Make scripts executable
chmod +x scripts/health-check.sh scripts/recovery.sh \
         scripts/restart-handler.sh cron/recovery-monitor.sh

# Add to crontab (every 15 minutes)
crontab -e
```

Add this line:
```cron
*/15 * * * * /opt/mining-grid/cron/recovery-monitor.sh >> /var/log/mining-grid-cron-monitor.log 2>&1
```

---

## Configuration

All AUTOSTART behaviour is controlled via environment variables (`.env` or shell):

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `MONGO_URI` | `mongodb://localhost:27017/mining_grid` | MongoDB connection string |
| `NODE_ENV` | `production` | Runtime environment |
| `API_HOST` | `localhost` | Host for health checks |
| `HEALTH_CHECK_TIMEOUT` | `10` | Curl timeout in seconds |
| `MEMORY_LIMIT_MB` | `512` | Max RSS before alert |
| `RECOVERY_MAX_ATTEMPTS` | `3` | Max recovery retries |
| `RECOVERY_DELAY` | `5` | Seconds between retries |
| `MAX_CONSECUTIVE_FAILURES` | `3` | Cron failures before recovery |
| `LOG_FILE` | `/var/log/mining-grid-health.log` | Health check log path |
| `CRON_LOG_FILE` | `/var/log/mining-grid-cron-monitor.log` | Cron monitor log path |

---

## Health Checks

The health check script (`scripts/health-check.sh`) verifies:

| Check | Description |
|-------|-------------|
| **Server process** | Confirms `node server.js` is running |
| **API health endpoint** | `GET /api/health` returns HTTP 200 |
| **Miners endpoint** | `GET /api/miners` is reachable |
| **Mining pool connectivity** | TCP connect to pool.bitcoin.com:3333 |
| **Memory usage** | RSS below configured limit |
| **MongoDB** | Ping via `mongosh` |

### Manual health check

```bash
# Standard output
bash scripts/health-check.sh

# JSON output (for integrations)
bash scripts/health-check.sh --json
```

---

## Recovery Procedures

### Automatic Recovery

1. **Immediate** – Docker `restart: always` restarts containers within seconds.
2. **Systemd** – `Restart=always` with `RestartSec=5` (max 3 per minute).
3. **Cron** – Every 15 minutes, `recovery-monitor.sh` checks health and calls `recovery.sh` after `MAX_CONSECUTIVE_FAILURES` failures.
4. **GitHub Actions** – Hourly health check workflow triggers `auto-recovery.yml` on failure.

### Manual Recovery

```bash
# Full recovery (stop → clean → reinstall → start → validate)
bash scripts/recovery.sh

# Graceful restart (with pre/post hooks)
bash scripts/restart-handler.sh --reason "manual restart"

# Docker restart
docker compose restart mining-grid

# Systemd restart
sudo systemctl restart mining-grid
```

---

## Monitoring

### View Logs

```bash
# Systemd journal
sudo journalctl -u mining-grid -f
sudo journalctl -u mining-grid -n 100

# Health check log
tail -f /var/log/mining-grid-health.log

# Recovery log
tail -f /var/log/mining-grid-recovery.log

# Cron monitor log
tail -f /var/log/mining-grid-cron-monitor.log

# Docker logs
docker logs mining-grid -f --tail 100
```

### Check Service Status

```bash
# Systemd
sudo systemctl status mining-grid
sudo systemctl list-timers mining-grid.timer

# Docker
docker compose ps
docker stats mining-grid

# Manual health check
bash scripts/health-check.sh --json
```

---

## Auto-Restart Triggers

| Trigger | Detection Time | Action |
|---------|----------------|--------|
| Container crash | Immediate | Docker restarts within 5s |
| Process crash | Immediate | Systemd restarts within 5s |
| Health check failure (3×) | 15–45 min | Cron triggers recovery |
| GitHub Actions health check | 1 hour | Workflow triggers recovery |

---

## Resource Limits

| Resource | Limit | Where configured |
|----------|-------|------------------|
| Memory | 512 MB | Systemd `MemoryMax`, Docker `memory` |
| CPU | 80% | Systemd `CPUQuota`, Docker `cpus` |
| Open files | 65536 | Systemd `LimitNOFILE` |
| Restart attempts | 3/min | Systemd `StartLimitBurst` |

---

## Troubleshooting

### Service won't start

1. Check logs: `sudo journalctl -u mining-grid -n 50`
2. Verify MongoDB is running: `systemctl status mongod`
3. Check `.env` for correct `MONGO_URI`
4. Run manually: `node server.js` and check for errors

### Health checks always fail

1. Confirm the port is open: `curl http://localhost:3000/api/health`
2. Check firewall: `sudo ufw status`
3. Verify environment variables in `.env`

### High memory usage

1. Check current usage: `ps -o rss= -p $(pgrep -f "node.*server.js")`
2. Increase `MEMORY_LIMIT_MB` or restart to free memory

### MongoDB connection errors

1. Check MongoDB status: `systemctl status mongod`
2. Verify connection string in `.env`
3. Test manually: `mongosh "$MONGO_URI"`
