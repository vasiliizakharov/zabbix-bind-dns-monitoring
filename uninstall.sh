#!/usr/bin/env bash
set -euo pipefail
rm -f /etc/zabbix/zabbix_agentd.d/userparameter_bind.conf
rm -f /usr/local/bin/zbx_bind_stats.sh
rm -f /usr/local/bin/zbx_bind_zones.sh
systemctl restart zabbix-agent2 2>/dev/null || systemctl restart zabbix-agent 2>/dev/null || true
echo "Uninstalled."
