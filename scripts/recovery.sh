#!/usr/bin/env bash
# =============================================================================
# Mining-Grid Recovery Script
# Stops, cleans up, and restarts the Mining-Grid service.
# Usage: bash scripts/recovery.sh [--force]
# Exit codes: 0 = recovery successful, 1 = recovery failed
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if present
if [ -f "$ROOT_DIR/.env" ]; then
  # shellcheck disable=SC1091
  set -o allexport
  source "$ROOT_DIR/.env"
  set +o allexport
fi

LOG_FILE="${LOG_FILE:-/var/log/mining-grid-recovery.log}"
RECOVERY_MAX_ATTEMPTS="${RECOVERY_MAX_ATTEMPTS:-3}"
RECOVERY_DELAY="${RECOVERY_DELAY:-5}"
FORCE="${1:-}"

log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$ts] [$level] $msg"
}

# ---------------------------------------------------------------------------
# Step 1 – Stop any running instance
# ---------------------------------------------------------------------------
stop_service() {
  log INFO "Stopping Mining-Grid service..."

  # systemd
  if command -v systemctl &>/dev/null && systemctl is-active --quiet mining-grid 2>/dev/null; then
    systemctl stop mining-grid
    log INFO "✅ Stopped via systemd"
    return 0
  fi

  # Docker
  if command -v docker &>/dev/null && docker ps -q -f name=mining-grid | grep -q .; then
    docker stop mining-grid
    log INFO "✅ Stopped Docker container"
    return 0
  fi

  # Bare process – use PID file if available for specificity
  local pid=""
  if [ -f /tmp/mining-grid.pid ]; then
    pid=$(cat /tmp/mining-grid.pid 2>/dev/null || echo "")
    kill -0 "$pid" 2>/dev/null || pid=""
  fi
  [ -z "$pid" ] && pid=$(pgrep -f "node ${ROOT_DIR}/server.js" | head -1 || echo "")
  [ -z "$pid" ] && pid=$(pgrep -f "node.*server.js" | head -1 || echo "")
  if [ -n "$pid" ]; then
    kill -SIGTERM "$pid"
    sleep 3
    if kill -0 "$pid" 2>/dev/null; then
      log WARN "Process $pid still running – sending SIGKILL"
      kill -SIGKILL "$pid" 2>/dev/null || true
    fi
    log INFO "✅ Process $pid stopped"
  else
    log INFO "No running process found – skipping stop"
  fi
}

# ---------------------------------------------------------------------------
# Step 2 – Cleanup
# ---------------------------------------------------------------------------
cleanup() {
  log INFO "Cleaning up temporary files..."
  find "$ROOT_DIR" -name "*.pid" -not -path "*/.git/*" -delete 2>/dev/null || true
  find "$ROOT_DIR" -name "*.lock.tmp" -not -path "*/.git/*" -delete 2>/dev/null || true
  find /tmp -name "mining-grid-*" -delete 2>/dev/null || true
  log INFO "✅ Cleanup complete"
}

# ---------------------------------------------------------------------------
# Step 3 – Reinstall dependencies
# ---------------------------------------------------------------------------
reinstall_deps() {
  log INFO "Reinstalling Node.js dependencies..."
  cd "$ROOT_DIR"
  if [ -f "package-lock.json" ]; then
    npm ci --prefer-offline 2>&1 | tail -5
  else
    npm install 2>&1 | tail -5
  fi
  log INFO "✅ Dependencies installed"
}

# ---------------------------------------------------------------------------
# Step 4 – Start service
# ---------------------------------------------------------------------------
start_service() {
  log INFO "Starting Mining-Grid service..."

  # systemd
  if command -v systemctl &>/dev/null && systemctl list-unit-files mining-grid.service &>/dev/null; then
    systemctl start mining-grid
    sleep "$RECOVERY_DELAY"
    if systemctl is-active --quiet mining-grid; then
      log INFO "✅ Started via systemd"
      return 0
    fi
    log ERROR "❌ systemd start failed"
    return 1
  fi

  # Docker Compose
  if [ -f "$ROOT_DIR/docker-compose.yml" ] && command -v docker &>/dev/null; then
    cd "$ROOT_DIR"
    docker compose up -d mining-grid
    sleep "$RECOVERY_DELAY"
    if docker ps -q -f name=mining-grid | grep -q .; then
      log INFO "✅ Started via Docker Compose"
      return 0
    fi
    log ERROR "❌ Docker Compose start failed"
    return 1
  fi

  log WARN "No service manager found – service must be started manually"
  return 1
}

# ---------------------------------------------------------------------------
# Step 5 – Validate recovery
# ---------------------------------------------------------------------------
validate_recovery() {
  local api_base="http://${API_HOST:-localhost}:${PORT:-3000}/api"
  log INFO "Validating recovery (waiting up to 30s)..."
  for i in $(seq 1 30); do
    if curl -sf --max-time 5 "${api_base}/health" > /dev/null 2>&1; then
      log INFO "✅ Service is healthy after recovery (${i}s)"
      return 0
    fi
    sleep 1
  done
  log ERROR "❌ Service did not become healthy within 30 seconds"
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log INFO "=== Mining-Grid Recovery started (max attempts: $RECOVERY_MAX_ATTEMPTS) ==="

ATTEMPT=0
SUCCESS=false

while [ $ATTEMPT -lt "$RECOVERY_MAX_ATTEMPTS" ]; do
  ATTEMPT=$((ATTEMPT + 1))
  log INFO "--- Recovery attempt $ATTEMPT / $RECOVERY_MAX_ATTEMPTS ---"

  stop_service   || true
  cleanup        || true
  reinstall_deps || true

  if start_service && validate_recovery; then
    SUCCESS=true
    break
  fi

  if [ $ATTEMPT -lt "$RECOVERY_MAX_ATTEMPTS" ]; then
    log WARN "Attempt $ATTEMPT failed – waiting ${RECOVERY_DELAY}s before retry..."
    sleep "$RECOVERY_DELAY"
  fi
done

if [ "$SUCCESS" = true ]; then
  log INFO "=== Recovery SUCCESSFUL after $ATTEMPT attempt(s) ==="
  exit 0
else
  log ERROR "=== Recovery FAILED after $RECOVERY_MAX_ATTEMPTS attempt(s) – manual intervention required ==="
  exit 1
fi
