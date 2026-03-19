#!/bin/bash
# game-health-check.sh - Game server health monitoring script
# Usage: ./game-health-check.sh [--daemon]

set -euo pipefail

# Configuration
SERVER_URL="${GAME_SERVER_URL:-http://localhost:3000}"
HEALTH_ENDPOINT="${SERVER_URL}/api/health"
LOG_FILE="${LOG_DIR:-/var/log/mining-grid}/health-check.log"
ALERT_ON_CONSECUTIVE_FAILURES="${ALERT_THRESHOLD:-3}"
CHECK_INTERVAL="${CHECK_INTERVAL_SECONDS:-60}"

# Counters
consecutive_failures=0

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"
}

check_server_health() {
  local http_status
  http_status=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 --max-time 10 "$HEALTH_ENDPOINT" 2>/dev/null || echo "000")

  if [ "$http_status" = "200" ]; then
    log "✅ Server health OK (HTTP $http_status)"
    return 0
  else
    log "❌ Server health check failed (HTTP $http_status)"
    return 1
  fi
}

check_mining_pools() {
  local pools=(
    "pool.foundryusapool.com:3333"
    "ss.antpool.com:3333"
    "mining.viabtc.com:3333"
  )

  # Check if nc is available; fall back to /dev/tcp if not
  local nc_available=false
  command -v nc &>/dev/null && nc_available=true

  local reachable=0
  for pool_addr in "${pools[@]}"; do
    local host port
    host=$(echo "$pool_addr" | cut -d: -f1)
    port=$(echo "$pool_addr" | cut -d: -f2)
    local connected=false
    if [ "$nc_available" = true ]; then
      nc -z -w5 "$host" "$port" 2>/dev/null && connected=true
    else
      # Bash built-in TCP fallback (no external tool needed)
      (echo >/dev/tcp/"$host"/"$port") 2>/dev/null && connected=true
    fi
    if [ "$connected" = true ]; then
      log "✅ Pool reachable: $pool_addr"
      ((reachable++))
    else
      log "⚠️  Pool unreachable: $pool_addr"
    fi
  done

  if [ "$reachable" -eq 0 ]; then
    log "❌ No mining pools reachable"
    return 1
  fi
  return 0
}

trigger_recovery() {
  log "🔄 Triggering recovery procedure..."
  if [ -f "$(dirname "$0")/mining-recovery.sh" ]; then
    bash "$(dirname "$0")/mining-recovery.sh"
  else
    log "⚠️  Recovery script not found, attempting service restart..."
    systemctl restart mining-grid.service 2>/dev/null || \
      log "❌ Could not restart service (not running as root or systemd unavailable)"
  fi
}

run_once() {
  if check_server_health && check_mining_pools; then
    consecutive_failures=0
    log "✅ All health checks passed"
    return 0
  else
    ((consecutive_failures++))
    log "⚠️  Health check failure count: $consecutive_failures/$ALERT_ON_CONSECUTIVE_FAILURES"
    if [ "$consecutive_failures" -ge "$ALERT_ON_CONSECUTIVE_FAILURES" ]; then
      log "🚨 Consecutive failure threshold reached, triggering recovery"
      trigger_recovery
      consecutive_failures=0
    fi
    return 1
  fi
}

run_daemon() {
  log "🚀 Starting Mining Grid health monitor daemon (interval: ${CHECK_INTERVAL}s)"
  while true; do
    run_once || true
    sleep "$CHECK_INTERVAL"
  done
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Main execution
if [ "${1:-}" = "--daemon" ]; then
  run_daemon
else
  run_once
fi
