#!/usr/bin/env bash
# =============================================================================
# Mining-Grid Restart Handler
# Gracefully restarts the Mining-Grid service, with pre/post-restart hooks.
# Usage: bash scripts/restart-handler.sh [--reason "reason string"]
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

LOG_FILE="${LOG_FILE:-/var/log/mining-grid-restart.log}"
REASON=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reason) REASON="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() {
  local level="$1"; shift
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] [$level] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$ts] [$level] $*"
}

# ---------------------------------------------------------------------------
# Pre-restart hook – capture state before restart
# ---------------------------------------------------------------------------
pre_restart() {
  log INFO "Pre-restart: capturing service state..."

  local api="http://${API_HOST:-localhost}:${PORT:-3000}/api"

  # Save stats snapshot
  local snapshot_file="/tmp/mining-grid-pre-restart-$(date +%s).json"
  if curl -sf --max-time 5 "${api}/stats" -o "$snapshot_file" 2>/dev/null; then
    log INFO "Pre-restart snapshot saved to $snapshot_file"
  else
    log WARN "Could not capture pre-restart stats (service may already be down)"
  fi

  # Record active miners count using node (avoids python3 dependency)
  local miners_count
  miners_count=$(curl -sf --max-time 5 "${api}/miners" 2>/dev/null \
    | node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8')); console.log(d.length);" 2>/dev/null || echo "unknown")
  log INFO "Active miners before restart: $miners_count"
}

# ---------------------------------------------------------------------------
# Perform restart
# ---------------------------------------------------------------------------
do_restart() {
  log INFO "Restarting Mining-Grid (reason: ${REASON:-not specified})..."

  # systemd
  if command -v systemctl &>/dev/null && systemctl list-unit-files mining-grid.service &>/dev/null 2>&1; then
    systemctl restart mining-grid
    log INFO "✅ Restarted via systemd"
    return 0
  fi

  # Docker Compose
  if [ -f "$ROOT_DIR/docker-compose.yml" ] && command -v docker &>/dev/null; then
    cd "$ROOT_DIR"
    docker compose restart mining-grid
    log INFO "✅ Restarted via Docker Compose"
    return 0
  fi

  # Bare process
  log WARN "No service manager – falling back to recovery script"
  bash "$SCRIPT_DIR/recovery.sh"
}

# ---------------------------------------------------------------------------
# Post-restart validation
# ---------------------------------------------------------------------------
post_restart() {
  log INFO "Post-restart: verifying service health..."

  local api="http://${API_HOST:-localhost}:${PORT:-3000}/api"
  local max_wait=30

  for i in $(seq 1 $max_wait); do
    if curl -sf --max-time 5 "${api}/health" > /dev/null 2>&1; then
      log INFO "✅ Service healthy after restart (${i}s)"
      return 0
    fi
    sleep 1
  done

  log ERROR "❌ Service not healthy after ${max_wait}s – triggering full recovery"
  bash "$SCRIPT_DIR/recovery.sh"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log INFO "=== Restart Handler invoked (reason: ${REASON:-not specified}) ==="

pre_restart  || true
do_restart
post_restart

log INFO "=== Restart Handler complete ==="
