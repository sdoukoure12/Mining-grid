#!/bin/bash
# mining-recovery.sh - Mining service recovery script
# Usage: ./mining-recovery.sh [--force]

set -euo pipefail

# Configuration
SERVICE_NAME="${SERVICE_NAME:-mining-grid}"
APP_DIR="${APP_DIR:-/opt/mining-grid}"
LOG_FILE="${LOG_DIR:-/var/log/mining-grid}/recovery.log"
MAX_RECOVERY_ATTEMPTS="${MAX_RECOVERY_ATTEMPTS:-3}"
RECOVERY_WAIT_SECONDS="${RECOVERY_WAIT_SECONDS:-10}"
SERVER_URL="${GAME_SERVER_URL:-http://localhost:3000}"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [RECOVERY] $*" | tee -a "$LOG_FILE"
}

check_service_running() {
  if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    return 0
  fi
  return 1
}

verify_recovery() {
  local max_wait=30
  local elapsed=0
  local interval=5

  log "⏳ Waiting for service to become healthy (max ${max_wait}s)..."
  while [ "$elapsed" -lt "$max_wait" ]; do
    local http_status
    http_status=$(curl -s -o /dev/null -w "%{http_code}" \
      --connect-timeout 5 --max-time 10 \
      "${SERVER_URL}/api/health" 2>/dev/null || echo "000")

    if [ "$http_status" = "200" ]; then
      log "✅ Service is healthy (HTTP $http_status)"
      return 0
    fi

    log "⏳ Service not yet healthy (HTTP $http_status), waiting ${interval}s..."
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  log "❌ Service did not become healthy within ${max_wait}s"
  return 1
}

backup_state() {
  local backup_dir="${APP_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
  log "📦 Creating state backup at $backup_dir..."
  mkdir -p "$backup_dir" 2>/dev/null || true

  # Backup logs if they exist
  if [ -d "${APP_DIR}/logs" ]; then
    cp -r "${APP_DIR}/logs" "$backup_dir/" 2>/dev/null || true
  fi

  log "✅ State backup completed"
}

attempt_recovery() {
  local attempt=$1
  log "🔄 Recovery attempt $attempt/$MAX_RECOVERY_ATTEMPTS..."

  # Back up state before recovery
  backup_state

  # Stop the service gracefully
  log "⏹️  Stopping service..."
  if check_service_running; then
    systemctl stop "$SERVICE_NAME" 2>/dev/null || kill -TERM "$(pgrep -f "node server.js")" 2>/dev/null || true
    sleep 2
  fi

  # Clear any lock files
  rm -f "${APP_DIR}/.lock" 2>/dev/null || true

  # Start the service
  log "▶️  Starting service..."
  if systemctl list-unit-files "${SERVICE_NAME}.service" &>/dev/null 2>/dev/null; then
    systemctl start "$SERVICE_NAME" 2>/dev/null || {
      # Fall back to direct Node.js start
      log "⚠️  systemctl failed, attempting direct start..."
      cd "$APP_DIR" && nohup node server.js >> "${LOG_FILE}" 2>&1 &
    }
  else
    # Not running as systemd, try direct start
    log "ℹ️  systemd not available, starting Node.js directly..."
    cd "$APP_DIR" && nohup node server.js >> "${LOG_FILE}" 2>&1 &
  fi

  sleep "$RECOVERY_WAIT_SECONDS"

  # Verify recovery
  if verify_recovery; then
    return 0
  fi
  return 1
}

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log "🚨 Mining service recovery initiated"
log "Service: $SERVICE_NAME | App dir: $APP_DIR"

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
  log "❌ Application directory not found: $APP_DIR"
  log "Please ensure the service is installed correctly."
  exit 1
fi

# Attempt recovery
for attempt in $(seq 1 "$MAX_RECOVERY_ATTEMPTS"); do
  if attempt_recovery "$attempt"; then
    log "🎉 Recovery successful on attempt $attempt"
    exit 0
  fi
  if [ "$attempt" -lt "$MAX_RECOVERY_ATTEMPTS" ]; then
    log "⏳ Waiting 30s before next attempt..."
    sleep 30
  fi
done

log "❌ All recovery attempts failed. Manual intervention required."
exit 1
