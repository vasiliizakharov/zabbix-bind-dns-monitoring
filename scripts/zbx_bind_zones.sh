#!/usr/bin/env bash
# Discover BIND zone files and report serial numbers.
# Usage:
#   zbx_bind_zones.sh discovery
#   zbx_bind_zones.sh serial <zone-name>
# Author: Vasilii Zakharov <vasiliiazakharov@gmail.com>

set -euo pipefail

ZONE_DIR="${ZBX_BIND_ZONE_DIR:-/etc/bind/zones}"
NAMED_CONF="${ZBX_BIND_NAMED_CONF:-/etc/bind/named.conf.local}"

mode="${1:-}"

discovery() {
  # Parse zone names from named.conf.local — best-effort regex.
  zones=$(grep -E '^[[:space:]]*zone[[:space:]]+"' "$NAMED_CONF" 2>/dev/null \
            | sed -E 's/^[[:space:]]*zone[[:space:]]+"([^"]+)".*/\1/' || true)

  first=1
  printf '{"data":['
  while IFS= read -r z; do
    [[ -z "$z" ]] && continue
    if [[ $first -eq 1 ]]; then first=0; else printf ','; fi
    printf '{"{#ZONE}":"%s"}' "$z"
  done <<< "$zones"
  printf ']}\n'
}

serial() {
  local zone="${1:-}"
  [[ -z "$zone" ]] && { echo 0; exit 0; }
  if command -v rndc >/dev/null 2>&1; then
    rndc zonestatus "$zone" 2>/dev/null \
      | awk -F': ' '/serial/{gsub(/[ \t]/,"",$2); print $2; exit}'
    return
  fi
  # Fallback: read SOA from zone file
  if [[ -f "$ZONE_DIR/db.$zone" ]]; then
    awk '/SOA/{flag=1} flag && $0 !~ /\(/{next} flag && /[0-9]/{print $1; exit}' "$ZONE_DIR/db.$zone"
  else
    echo 0
  fi
}

case "$mode" in
  discovery) discovery ;;
  serial)    serial "${2:-}" ;;
  *) echo "usage: $0 {discovery|serial ZONE}" >&2; exit 2 ;;
esac
