# TeaTaxTower — Homelab Infrastructure Case Study

A sanitised case study of a self-hosted **Unraid + Docker** homelab: a handful of
services published to the internet from behind CGNAT, with host administration
kept entirely private.

## About This Lab:
- 🖥️ Small-form-factor server running Unraid with a containerised service stack
- 🌐 Public access with **no inbound port forwarding** — the host dials *out* to a cloud edge
- 🔐 Administration over an encrypted mesh VPN, never published to the internet
- 💾 Storage laid out so imports **hardlink** instead of silently duplicating
- 📋 Runbooks for diagnostics, maintenance, and every failure that has happened once
- 🧪 Written up as a portfolio case study — [architecture](docs/architecture.md) · [operations](docs/operations.md) · [lessons](docs/lessons-learned.md)

## Platform & OS:
![Unraid](https://img.shields.io/badge/Unraid-F15A2C?style=for-the-badge&logo=unraid&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

## Containerisation:
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)

## Networking & Remote Access:
![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare%20Tunnel-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Tailscale](https://img.shields.io/badge/Tailscale-242424?style=for-the-badge&logo=tailscale&logoColor=white)
![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=for-the-badge&logo=wireguard&logoColor=white)
![CGNAT](https://img.shields.io/badge/CGNAT-1F2937?style=for-the-badge)

## Storage & Filesystems:
![XFS](https://img.shields.io/badge/XFS-4B5563?style=for-the-badge)
![BTRFS](https://img.shields.io/badge/BTRFS-4B5563?style=for-the-badge)
![Hardlinks](https://img.shields.io/badge/Hardlinks-4B5563?style=for-the-badge)
![Parity Protection](https://img.shields.io/badge/Parity%20Protection-4B5563?style=for-the-badge)

## Monitoring & Diagnostics:
![S.M.A.R.T.](https://img.shields.io/badge/S.M.A.R.T.-0A7E8C?style=for-the-badge)
![smartmontools](https://img.shields.io/badge/smartmontools-0A7E8C?style=for-the-badge)
![Container Logs](https://img.shields.io/badge/Container%20Logs-0A7E8C?style=for-the-badge)

## Documentation:
![Markdown](https://img.shields.io/badge/Markdown-000000?style=for-the-badge&logo=markdown&logoColor=white)
![Mermaid](https://img.shields.io/badge/Mermaid-FF3670?style=for-the-badge&logo=mermaid&logoColor=white)
![Notion](https://img.shields.io/badge/Notion-000000?style=for-the-badge&logo=notion&logoColor=white)

---

> This repository contains sanitised documentation and example configuration
> only. It deliberately excludes live credentials, real hostnames, IP addresses,
> domains, tunnel identifiers, media, user data, and production configuration
> exports.

## Highlights

- **Containerised services with persistent-storage conventions.** Every service
  keeps its configuration and state under a predictable `appdata` path, and its
  working data under a shared parent path, so services can be rebuilt from
  images without losing state.
- **Outbound-tunnel design behind CGNAT.** The connection has no usable public
  inbound path, so the host makes an authenticated outbound connection to the
  Cloudflare edge and selected application routes are published through it.
- **Private remote administration over an encrypted mesh VPN.** The management
  UI and SSH are never published to the internet; administration happens over a
  Tailscale overlay between enrolled devices.
- **Storage, mount-path, and hardlink considerations.** Related containers share
  a consistent host-level parent mount so imports can hardlink instead of
  duplicating data.
- **Diagnostics, maintenance, and troubleshooting.** Repeatable commands for
  container state, mount mappings, capacity, disk health, and tunnel/VPN
  reachability, plus weekly, monthly, and quarterly routines.
- **Lessons from disk health, access boundaries, and recovery planning.** What
  a SMART warning should actually trigger, why parity is not a backup, and why
  public applications and host administration are different risk classes.

## Architecture at a glance

```text
Public internet
    |
    v
Outbound tunnel provider
    |
    v
Container host
    |-- Media service
    |-- Request-management service
    `-- Game-service manager

Private administration
    |
    v
Encrypted mesh VPN
    |
    `-- Host administration interface and SSH
```

## Repository guide

| Path | Contents |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Design goals, network model, service flow, storage conventions, security boundaries |
| [`docs/operations.md`](docs/operations.md) | Diagnostics, maintenance schedule, and troubleshooting runbooks |
| [`docs/lessons-learned.md`](docs/lessons-learned.md) | What the build actually taught, written as conclusions |
| [`diagrams/system-overview.md`](diagrams/system-overview.md) | Mermaid overview of the generic component layout |
| [`examples/`](examples/) | Illustrative, non-deployable configuration and a diagnostic helper script |
| [`SECURITY.md`](SECURITY.md) | What is excluded from this repository, and how to report a problem |

## Concepts covered

Container networking · outbound tunnel ingress and default-deny routing ·
overlay/mesh VPN identity and device revocation · Linux operations · share and
mount-path design · hardlinks and filesystem boundaries · SMART trend
monitoring · backup versus redundancy and tested recovery

## Scope

This is a personal learning and infrastructure case study. It is **not** a
deployment guide, and the examples here are illustrative rather than runnable.
Anyone building something similar should treat the material as a description of
reasoning and trade-offs, then design against their own network, hardware, and
threat model.

## Licence

Released under the [MIT License](LICENSE).
