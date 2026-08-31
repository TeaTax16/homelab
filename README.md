# TeaTaxTower — Homelab Infrastructure Case Study

TeaTaxTower is a small self-hosted homelab running Unraid with a Docker-based
service stack. This repository is a **sanitised case study** of how it is
designed, operated, and maintained: a set of selected applications is reachable
remotely from an internet connection sitting behind CGNAT, without exposing the
host itself and without conventional inbound port forwarding.

It documents architecture decisions, operational routines, security boundaries,
and the lessons that came out of running the system — not the system itself.

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
  inbound path, so the host makes an authenticated outbound connection to a
  cloud edge and selected application routes are published through it.
- **Private remote administration over an encrypted mesh VPN.** The management
  UI and SSH are never published to the internet; administration happens over a
  peer-to-peer overlay between enrolled devices.
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

## Technologies and concepts

Unraid · Docker · container networking · outbound tunnels · encrypted mesh VPN ·
Linux operations · SMART monitoring · storage and share management · hardlinks
and filesystem boundaries · backup and recovery planning

## Scope

This is a personal learning and infrastructure case study. It is **not** a
deployment guide, and the examples here are illustrative rather than runnable.
Anyone building something similar should treat the material as a description of
reasoning and trade-offs, then design against their own network, hardware, and
threat model.

## Licence

Released under the [MIT License](LICENSE).
