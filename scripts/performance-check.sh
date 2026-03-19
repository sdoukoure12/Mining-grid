#!/bin/bash
# performance-check.sh - Performance verification script for Mining Grid
# Usage: ./performance-check.sh [--json]

set -euo pipefail

# Configuration
SERVER_URL="${GAME_SERVER_URL:-http://localhost:3000}"
LOG_FILE="${LOG_DIR:-/var/log/mining-grid}/performance.log"
HASHRATE_THRESHOLD="${HASHRATE_THRESHOLD:-100}"  # TH/s minimum
TEMP_WARNING="${TEMP_WARNING:-70}"               # °C
TEMP_CRITICAL="${TEMP_CRITICAL:-85}"             # °C

JSON_OUTPUT=false
if [ "${1:-}" = "--json" ]; then
  JSON_OUTPUT=true
fi

log() {
  if [ "$JSON_OUTPUT" = false ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"
  fi
}

fetch_stats() {
  curl -s --connect-timeout 5 --max-time 10 \
    "${SERVER_URL}/api/stats" 2>/dev/null || echo "{}"
}

fetch_miners() {
  curl -s --connect-timeout 5 --max-time 10 \
    "${SERVER_URL}/api/miners" 2>/dev/null || echo "[]"
}

check_response_time() {
  local start_ms
  local end_ms
  local duration_ms

  start_ms=$(date +%s%3N)
  curl -s -o /dev/null --connect-timeout 5 --max-time 10 \
    "${SERVER_URL}/api/health" 2>/dev/null || true
  end_ms=$(date +%s%3N)
  duration_ms=$((end_ms - start_ms))

  log "API response time: ${duration_ms}ms"
  echo "$duration_ms"
}

# Main checks
log "🔍 Starting performance check..."
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

STATS=$(fetch_stats)
MINERS=$(fetch_miners)
RESPONSE_TIME=$(check_response_time)

# Parse stats using node (already installed as dependency)
node -e "
const stats = JSON.parse(process.env.STATS || '{}');
const miners = JSON.parse(process.env.MINERS || '[]');
const responseTime = parseInt(process.env.RESPONSE_TIME || '0', 10);
const HASHRATE_THRESHOLD = parseFloat(process.env.HASHRATE_THRESHOLD || '100');
const TEMP_WARNING = parseFloat(process.env.TEMP_WARNING || '70');
const TEMP_CRITICAL = parseFloat(process.env.TEMP_CRITICAL || '85');

const report = {
  timestamp: new Date().toISOString(),
  responseTimeMs: responseTime,
  totalMiners: stats.totalMiners || 0,
  activeMiners: stats.activeMiners || 0,
  totalHashrate: parseFloat((stats.totalHashrate || 0).toFixed(2)),
  averageTemperature: parseFloat((stats.averageTemperature || 0).toFixed(1)),
  totalPower: stats.totalPower || 0,
  warnings: [],
  status: 'ok'
};

if (report.totalHashrate < HASHRATE_THRESHOLD && report.activeMiners > 0) {
  report.warnings.push('Low hashrate: ' + report.totalHashrate + ' TH/s (threshold: ' + HASHRATE_THRESHOLD + ')');
  report.status = 'warning';
}

if (report.averageTemperature >= TEMP_CRITICAL) {
  report.warnings.push('CRITICAL temperature: ' + report.averageTemperature + '°C');
  report.status = 'critical';
} else if (report.averageTemperature >= TEMP_WARNING) {
  report.warnings.push('High temperature: ' + report.averageTemperature + '°C');
  if (report.status === 'ok') report.status = 'warning';
}

if (responseTime > 2000) {
  report.warnings.push('Slow API response: ' + responseTime + 'ms');
  if (report.status === 'ok') report.status = 'warning';
}

if (process.env.JSON_OUTPUT === 'true') {
  console.log(JSON.stringify(report, null, 2));
} else {
  console.log('📊 Performance Report:', new Date().toISOString());
  console.log('Active miners:', report.activeMiners + '/' + report.totalMiners);
  console.log('Total hashrate:', report.totalHashrate, 'TH/s');
  console.log('Average temperature:', report.averageTemperature, '°C');
  console.log('API response time:', report.responseTimeMs, 'ms');
  if (report.warnings.length > 0) {
    console.warn('⚠️  Warnings:', report.warnings.join('; '));
  }
  console.log('Status:', report.status === 'ok' ? '✅ OK' : '⚠️  ' + report.status.toUpperCase());
}

if (report.status === 'critical') process.exit(2);
if (report.status === 'warning') process.exit(1);
" STATS="$STATS" MINERS="$MINERS" RESPONSE_TIME="$RESPONSE_TIME" \
  HASHRATE_THRESHOLD="$HASHRATE_THRESHOLD" \
  TEMP_WARNING="$TEMP_WARNING" TEMP_CRITICAL="$TEMP_CRITICAL" \
  JSON_OUTPUT="$JSON_OUTPUT"
