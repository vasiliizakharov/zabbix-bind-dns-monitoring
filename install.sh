#!/usr/bin/env bash
# Idempotent installer for zabbix-bind-dns-monitoring.
# Author: Vasilii Zakharov <vasiliiazakharov@gmail.com>

set -euo pipefail

if ! id zabbix >/dev/null 2>&1; then
  echo "ERROR: user 'zabbix' not found." >&2
  exit 1
fi

CONF_DIR=/etc/zabbix/zabbix_agentd.d
SCRIPT_DIR=/usr/local/bin
SELF=$(cd "$(dirname "$0")" && pwd)

install -d -m 0755 "$CONF_DIR"
install -m 0644 "$SELF/userparameter_bind.conf" -t "$CONF_DIR/"
install -m 0755 "$SELF/scripts/zbx_bind_stats.sh" -t "$SCRIPT_DIR/"
install -m 0755 "$SELF/scripts/zbx_bind_zones.sh" -t "$SCRIPT_DIR/"

if systemctl restart zabbix-agent2 2>/dev/null; then
  echo "Restarted zabbix-agent2"
elif systemctl restart zabbix-agent 2>/dev/null; then
  echo "Restarted zabbix-agent"
fi

cat <<'NOTE'

Make sure BIND statistics-channel is enabled in named.conf.options:

    statistics-channels {
        inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
    };

Verify:

    curl -s http://127.0.0.1:8053/json | head -c 200

Optional: install jq for cleaner parsing.

NOTE
