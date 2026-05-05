#!/usr/bin/env bash
# BIND9 statistics-channel parser for Zabbix.
# Usage:
#   zbx_bind_stats.sh json [url]      raw JSON
#   zbx_bind_stats.sh qtype A
#   zbx_bind_stats.sh qtotal
#   zbx_bind_stats.sh rcode NOERROR|NXDOMAIN|SERVFAIL|REFUSED
#   zbx_bind_stats.sh hitrate
# Default URL: ${ZBX_BIND_STATS_URL:-http://127.0.0.1:8053/json}
# Author: Vasilii Zakharov <vasiliiazakharov@gmail.com>

set -euo pipefail

mode="${1:-}"
arg="${2:-}"

URL="${ZBX_BIND_STATS_URL:-http://127.0.0.1:8053/json}"
[[ -n "$arg" && "$mode" == "json" ]] && URL="$arg"

fetch() {
  curl -s -f -m 5 "$URL" 2>/dev/null
}

case "$mode" in
  json)
    fetch || echo '{}'
    ;;
  qtype)
    json=$(fetch || echo '{}')
    # BIND 9.10+ schema: opcodes / qtypes per-view; aggregate over views.
    # Fall back gracefully if jq is missing.
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$json" | jq --arg t "$arg" '
        [ (.views // {}) | to_entries[] | .value.resolver.qtypes // {} | .[$t] // 0 ] | add // 0
      '
    else
      printf '%s' "$json" | grep -oE "\"$arg\"[[:space:]]*:[[:space:]]*[0-9]+" | awk -F: '{s+=$2} END{print s+0}'
    fi
    ;;
  qtotal)
    json=$(fetch || echo '{}')
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$json" | jq '
        [ (.views // {}) | to_entries[] | .value.resolver.qtypes // {} | to_entries[].value ] | add // 0
      '
    else
      printf '%s' "$json" | grep -oE '"qtypes"[^}]*}' | grep -oE '[0-9]+' | awk '{s+=$1} END{print s+0}'
    fi
    ;;
  rcode)
    json=$(fetch || echo '{}')
    if command -v jq >/dev/null 2>&1; then
      printf '%s' "$json" | jq --arg r "$arg" '(.nsstats // {}) | .[$r] // .["QryNXDOMAIN"] // 0' \
        | head -1
    else
      printf '%s' "$json" | grep -oE "\"$arg\"[[:space:]]*:[[:space:]]*[0-9]+" | head -1 | awk -F: '{print $2+0}'
    fi
    ;;
  hitrate)
    json=$(fetch || echo '{}')
    if command -v jq >/dev/null 2>&1; then
      hits=$(printf '%s' "$json" | jq '[ (.views // {}) | to_entries[] | .value.cachestats // {} | .CacheHits // 0 ] | add // 0')
      miss=$(printf '%s' "$json" | jq '[ (.views // {}) | to_entries[] | .value.cachestats // {} | .CacheMisses // 0 ] | add // 0')
    else
      hits=$(printf '%s' "$json" | grep -oE '"CacheHits"[[:space:]]*:[[:space:]]*[0-9]+' | awk -F: '{s+=$2} END{print s+0}')
      miss=$(printf '%s' "$json" | grep -oE '"CacheMisses"[[:space:]]*:[[:space:]]*[0-9]+' | awk -F: '{s+=$2} END{print s+0}')
    fi
    total=$((hits + miss))
    if [[ $total -le 0 ]]; then
      echo 0
    else
      awk -v h="$hits" -v t="$total" 'BEGIN { printf "%.4f", h*100/t }'
    fi
    ;;
  *)
    echo "usage: $0 {json|qtype TYPE|qtotal|rcode CODE|hitrate}" >&2
    exit 2
    ;;
esac
