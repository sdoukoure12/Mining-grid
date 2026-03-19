#!/usr/bin/env bash
# =============================================================================
# Mining-Grid Health Check Script
# Checks game server health, mining pool connectivity, and resource usage.
# Usage: bash scripts/health-check.sh [--json]
# Exit codes: 0 = healthy, 1 = unhealthy
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration (override via environment or .env)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if present
if [ -f "$ROOT_DIR/.env" ]; then
  # shellcheck disable=SC1091
  set -o allexport
  source "$ROOT_DIR/.env"
  set +o allexport
fi

API_HOST="${API_HOST:-localhost}"
API_PORT="${PORT:-3000}"
API_BASE="http://${API_HOST}:${API_PORT}/api"
LOG_FILE="${LOG_FILE:-/var/log/mining-grid-health.log}"
TIMEOUT="${HEALTH_CHECK_TIMEOUT:-10}"
JSON_OUTPUT=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$ts] [$level] $msg"
}

check_http() {
  local url="$1"
  local expected="${2:-200}"
  local status
  status=$(curl -sf --max-time "$TIMEOUT" -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  echo "$status"
}

# ---------------------------------------------------------------------------
# Health checks
# ---------------------------------------------------------------------------
RESULTS=()
OVERALL=0

# 1. Server process check
check_server_process() {
  if pgrep -f "node.*server.js" > /dev/null 2>&1; then
    log INFO "✅ Server process is running"
    RESULTS+=("server_process:ok")
  else
    log ERROR "❌ Server process is NOT running"
    RESULTS+=("server_process:fail")
    OVERALL=1
  fi
}

# 2. API health endpoint
check_api_health() {
  local status
  status=$(check_http "${API_BASE}/health")
  if [ "$status" = "200" ]; then
    log INFO "✅ API health endpoint OK (HTTP $status)"
    RESULTS+=("api_health:ok")
  else
    log ERROR "❌ API health endpoint returned HTTP $status"
    RESULTS+=("api_health:fail")
    OVERALL=1
  fi
}

# 3. Miners list endpoint
check_miners_endpoint() {
  local status
  status=$(check_http "${API_BASE}/miners")
  if [ "$status" = "200" ] || [ "$status" = "503" ]; then
    log INFO "✅ Miners endpoint reachable (HTTP $status)"
    RESULTS+=("miners_endpoint:ok")
  else
    log ERROR "❌ Miners endpoint returned HTTP $status"
    RESULTS+=("miners_endpoint:fail")
    OVERALL=1
  fi
}

# 4. Mining pool connectivity
check_pool_connectivity() {
  local pools=("pool.bitcoin.com:3333" "stratum.slushpool.com:3333")
  local reachable=0
  for pool in "${pools[@]}"; do
    local host="${pool%%:*}"
    local port="${pool##*:}"
    if timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
      log INFO "✅ Pool $pool reachable"
      reachable=$((reachable + 1))
    else
      log WARN "⚠️  Pool $pool unreachable"
    fi
  done
  if [ $reachable -gt 0 ]; then
    RESULTS+=("pool_connectivity:ok")
  else
    log ERROR "❌ All mining pools unreachable"
    RESULTS+=("pool_connectivity:warn")
    # Warn only – pool outages are external
  fi
}

# 5. Resource usage
check_resources() {
  # Memory (RSS) of the node process
  local pid
  pid=$(pgrep -f "node.*server.js" | head -1 || echo "")
  if [ -n "$pid" ]; then
    local rss_kb
    rss_kb=$(ps -o rss= -p "$pid" 2>/dev/null || echo 0)
    local rss_mb=$(( rss_kb / 1024 ))
    local mem_limit="${MEMORY_LIMIT_MB:-512}"
    if [ "$rss_mb" -lt "$mem_limit" ]; then
      log INFO "✅ Memory usage ${rss_mb}MB (limit ${mem_limit}MB)"
      RESULTS+=("memory_usage:ok")
    else
      log ERROR "❌ Memory ${rss_mb}MB exceeds limit ${mem_limit}MB"
      RESULTS+=("memory_usage:fail")
      OVERALL=1
    fi
  else
    RESULTS+=("memory_usage:skip")
  fi
}

# 6. MongoDB connectivity
check_mongodb() {
  if command -v mongosh &>/dev/null; then
    if mongosh --quiet --eval "db.adminCommand({ping:1})" \
         "${MONGO_URI:-mongodb://localhost:27017/mining_grid}" &>/dev/null; then
      log INFO "✅ MongoDB connection OK"
      RESULTS+=("mongodb:ok")
    else
      log ERROR "❌ MongoDB connection failed"
      RESULTS+=("mongodb:fail")
      OVERALL=1
    fi
  else
    log WARN "⚠️  mongosh not available – skipping MongoDB check"
    RESULTS+=("mongodb:skip")
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

log INFO "=== Mining-Grid Health Check started ==="

check_server_process
check_api_health
check_miners_endpoint
check_pool_connectivity
check_resources
check_mongodb

log INFO "=== Health Check complete – overall: $([ $OVERALL -eq 0 ] && echo HEALTHY || echo UNHEALTHY) ==="

if [ "$JSON_OUTPUT" = true ]; then
  printf '{"status":"%s","checks":{' "$([ $OVERALL -eq 0 ] && echo healthy || echo unhealthy)"
  first=true
  for r in "${RESULTS[@]}"; do
    k="${r%%:*}"; v="${r##*:}"
    [ "$first" = true ] && first=false || printf ','
    printf '"%s":"%s"' "$k" "$v"
  done
  printf '},"timestamp":"%s"}\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
fi

exit $OVERALL
