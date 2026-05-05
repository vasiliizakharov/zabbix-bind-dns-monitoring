# zabbix-bind-dns-monitoring

Zabbix 7.0 template for ISC BIND9 (`named`) using the built-in
statistics-channel JSON endpoint. No PowerDNS-API gymnastics, no SNMP — just
HTTP and a couple of bash helpers.

## What it monitors

- Total query rate
- Per-type query rates: A, AAAA, MX, TXT, PTR
- Response code counters: NOERROR, NXDOMAIN, SERVFAIL, REFUSED
- Cache hit rate (CacheHits / (CacheHits + CacheMisses))
- LLD discovery of zones from `named.conf.local` with per-zone SOA serial

## Requirements

- BIND 9.10+ with `statistics-channels` enabled
- Zabbix agent 5.0+
- Optional: `jq` (script falls back to grep parsing if absent)

### BIND configuration

```bind
options {
    // ... your existing options ...
};

statistics-channels {
    inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
};
```

Reload BIND and verify:

```sh
curl -s http://127.0.0.1:8053/json | head -c 500
```

## Install

```sh
sudo ./install.sh
```

Then import `template/template.yaml` in the Zabbix UI.

## Items

See `userparameter_bind.conf`. Highlights:

- `bind.queries.total`, `bind.queries.IN.{A,AAAA,MX,TXT,PTR}`
- `bind.responses.{NOERROR,NXDOMAIN,SERVFAIL,REFUSED}`
- `bind.cache.hitrate`
- `bind.zone.discovery` (LLD)
- `bind.zone.serial[zone]`

## Triggers

See [docs/triggers.md](docs/triggers.md).

## Macros

| Macro | Default |
|-------|---------|
| `{$ZBX.BIND.STATS_URL}` | `http://127.0.0.1:8053/json` |
| `{$ZBX.BIND.SERVFAIL.RATE.HIGH}` | `5` per minute |
| `{$ZBX.BIND.HITRATE.LOW}` | `70` |

## Troubleshooting

- `bind.queries.total` empty: check that BIND statistics-channel listens on
  the URL set in `{$ZBX.BIND.STATS_URL}`. Try `curl` first.
- `bind.zone.discovery` empty: edit `ZBX_BIND_NAMED_CONF` env var if your
  zones live in `/etc/bind/named.conf` directly instead of
  `named.conf.local`.
- Per-type counters returning `0`: BIND 9.16+ groups them under
  `views.<view>.resolver.qtypes` — the parser handles this. With multiple
  views, totals are summed.

## License

MIT — see [LICENSE](LICENSE).
