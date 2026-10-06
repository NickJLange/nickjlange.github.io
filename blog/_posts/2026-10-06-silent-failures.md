---
title: One VPN User, Four Silent Failures
date: 2026-10-06
---

The task: add one person to our home VPN. iPhone + laptop, three sites. Should be an hour.

Two evenings later, nothing had ever thrown an error, and yet:

- The Wisconsin hub (rebuilt last week) was listening on a port the router didn't forward.
- My phone had the hub's **old** public key, then the wrong tunnel `Address`. The app said *connected* the whole time. 🙃
- Japan's hostname still pointed at last month's IP.
- The script that "deletes" the Raspberry Pi default user had been quietly doing nothing, leaving that user alive with passwordless sudo on a few boxes.

```text
phone ──UDP──▶ router ──▶ Pi hub (wg0) ──▶ router ──▶ internet
                  ▲                          │
                  └── static route, no NAT ──┘
```

## Lessons Learned 🧠
- WireGuard never tells you why. `tcpdump` packet sizes do: 148 bytes = handshake initiation, 92 = response, 64 = cookie reply, 32 = keepalive. Anything else is data (inner packet, padded, + 32).
- WireGuard servers can't push DNS. Put `DNS =` in every client config.
- `killall -q ... && userdel` skips `userdel` when there's nothing to kill. `ignore_errors: true` made sure I never found out.
- Renaming an account is a free audit.

Full write-up with diagrams and the packet-size cheat sheet: [New WireGuard Tricks (and a Root-Shaped &&)](https://www.5l-labs.com/self-hosted-iot/wireguard-silent-failures)

Fixes: [mkrasberry #50](https://github.com/NickJLange/mkrasberry/pull/50) · [mkrasberry #51](https://github.com/NickJLange/mkrasberry/pull/51)
