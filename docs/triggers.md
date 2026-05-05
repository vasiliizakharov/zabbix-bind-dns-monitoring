# Triggers

| Name | Severity | Condition |
|------|----------|-----------|
| BIND: SERVFAIL rate is high | Warning | `avg(bind.responses.SERVFAIL, 5m) * 60 > {$ZBX.BIND.SERVFAIL.RATE.HIGH}` |
| BIND: cache hit rate is low | Info | `bind.cache.hitrate < {$ZBX.BIND.HITRATE.LOW}` |
| BIND: statistics-channel unreachable | High | no data on `bind.queries.total` for 5m |

## Macros

| Macro | Default |
|-------|---------|
| `{$ZBX.BIND.STATS_URL}` | `http://127.0.0.1:8053/json` |
| `{$ZBX.BIND.SERVFAIL.RATE.HIGH}` | 5 (per minute) |
| `{$ZBX.BIND.HITRATE.LOW}` | 70 |

## Zone serials

LLD discovers zones from `/etc/bind/named.conf.local`. To monitor secondary
zones served by IXFR, the prototype calls `rndc zonestatus`. If `rndc` is not
configured for the zabbix user, the script falls back to reading the zone
file SOA serial from `/etc/bind/zones/db.<zone>`.
