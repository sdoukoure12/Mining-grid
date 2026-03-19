#!/usr/bin/env bash
# =============================================================================
# Mining-Grid Cron Recovery Monitor
# Run every 15 minutes via cron to detect and recover from crashes.
#
# Recommended crontab entry:
#   */15 * * * * /opt/mining-grid/cron/recovery-monitor.sh >> /var/log/mining-grid-cron-monitor.log 2>&1
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env" ]; then
  # shellcheck disable=SC1091
  set -o allexport
  source "$ROOT_DIR/.env"
  set +o allexport
fi

LOG_FILE="${CRON_LOG_FILE:-/var/log/mining-grid-cron-monitor.log}"
API_BASE="http://${API_HOST:-localhost}:${PORT:-3000}/api"
LOCK_FILE="/tmp/mining-grid-cron-monitor.lock"
MAX_CONSECUTIVE_FAILURES="${MAX_CONSECUTIVE_FAILURES:-3}"
STATE_FILE="/tmp/mining-grid-failure-count"

log() {
  local level="$1"; shift
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] [$level] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$ts] [$level] $*"
}

# Prevent overlapping cron runs using flock for atomic locking
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log WARN "Another monitor instance is already running – exiting"
  exit 0
fi

# ---------------------------------------------------------------------------
# Read / write consecutive failure count
# ---------------------------------------------------------------------------
get_failure_count() {
  cat "$STATE_FILE" 2>/dev/null || echo 0
}

set_failure_count() {
  echo "$1" > "$STATE_FILE"
}

# ---------------------------------------------------------------------------
# Check if service is alive
# ---------------------------------------------------------------------------
is_service_healthy() {
  curl -sf --max-time 8 "${API_BASE}/health" > /dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log INFO "=== Cron monitor check started ==="

FAILURES=$(get_failure_count)

if is_service_healthy; then
  log INFO "✅ Service is healthy"
  set_failure_count 0
else
  FAILURES=$((FAILURES + 1))
  set_failure_count "$FAILURES"
  log WARN "⚠️  Service health check failed (consecutive failures: $FAILURES)"

  if [ "$FAILURES" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
    log ERROR "❌ Service has been unhealthy for $FAILURES checks – triggering recovery"
    if bash "$ROOT_DIR/scripts/recovery.sh"; then
      log INFO "✅ Recovery completed successfully"
      set_failure_count 0
    else
      log ERROR "❌ Recovery failed – manual intervention required"
    fi
  else
    log WARN "Waiting for more failures before triggering recovery ($FAILURES / $MAX_CONSECUTIVE_FAILURES)"
  fi
fi

log INFO "=== Cron monitor check complete ==="
