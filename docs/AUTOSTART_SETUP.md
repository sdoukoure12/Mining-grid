# Mining Grid AUTOSTART Setup Guide

This document describes how to set up automatic startup and recovery for the Mining Grid game server on a Linux system.

## Prerequisites

- Ubuntu 20.04+ / Debian 11+ / any systemd-based Linux distribution
- Node.js 18+ installed
- `curl`, `netcat` (`nc`) installed
- Root or sudo access for systemd configuration

## Installation

### 1. Deploy the Application

```bash
# Clone the repository
git clone https://github.com/sdoukoure12/Mining-grid.git /opt/mining-grid
cd /opt/mining-grid

# Create a dedicated user
sudo useradd --system --no-create-home --shell /bin/false mining-grid
sudo chown -R mining-grid:mining-grid /opt/mining-grid

# Install Node.js dependencies
npm ci --only=production

# Create log directory
sudo mkdir -p /var/log/mining-grid
sudo chown mining-grid:mining-grid /var/log/mining-grid
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
nano /opt/mining-grid/.env
```

Key environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `production` | Node environment |
| `MONGODB_URI` | `mongodb://localhost:27017/mining-grid` | MongoDB connection |
| `GAME_SERVER_URL` | `http://localhost:3000` | Server URL for health checks |
| `LOG_DIR` | `/var/log/mining-grid` | Log directory |

### 3. Install Systemd Services

```bash
# Copy service files
sudo cp /opt/mining-grid/systemd/mining-grid.service /etc/systemd/system/
sudo cp /opt/mining-grid/systemd/mining-grid-monitor.service /etc/systemd/system/
sudo cp /opt/mining-grid/systemd/mining-grid.timer /etc/systemd/system/

# Make scripts executable
chmod +x /opt/mining-grid/scripts/*.sh

# Reload systemd
sudo systemctl daemon-reload

# Enable and start services
sudo systemctl enable mining-grid.service
sudo systemctl enable mining-grid-monitor.service
sudo systemctl enable mining-grid.timer
sudo systemctl start mining-grid.service
sudo systemctl start mining-grid-monitor.service
sudo systemctl start mining-grid.timer
```

### 4. Verify Services

```bash
# Check service status
sudo systemctl status mining-grid.service
sudo systemctl status mining-grid-monitor.service
sudo systemctl list-timers mining-grid.timer

# View logs
sudo journalctl -u mining-grid -f
sudo journalctl -u mining-grid-monitor -f
```

### 5. Install Cron Jobs (Alternative to Systemd)

If you prefer cron-based monitoring instead of or in addition to systemd timers:

```bash
# Install cron jobs for the mining-grid user
sudo crontab -u mining-grid /opt/mining-grid/cron/mining-cron

# Verify
sudo crontab -u mining-grid -l
```

## Docker Setup

For containerised deployment:

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f mining-grid

# Stop services
docker compose down
```

## GitHub Actions

The repository includes three automated workflows:

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| `autostart-game-health.yml` | Every hour | Health monitoring |
| `auto-recovery-miner.yml` | On demand / triggered | Service recovery |
| `performance-monitor.yml` | Every 30 min | Performance tracking |

These workflows require the `GAME_SERVER_URL` secret to be set in your repository settings (if monitoring an external server).

## Testing AUTOSTART

```bash
# Test health check script
bash /opt/mining-grid/scripts/game-health-check.sh

# Test recovery script (dry run)
bash /opt/mining-grid/scripts/mining-recovery.sh

# Test performance check
bash /opt/mining-grid/scripts/performance-check.sh

# Simulate a crash and verify auto-restart
sudo systemctl kill mining-grid.service
sleep 10
sudo systemctl status mining-grid.service
```

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.
