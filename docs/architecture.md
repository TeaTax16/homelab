# Architecture

## Design goals

The homelab was built around five goals, in priority order:

1. **A small number of applications should be usable from outside the house**,
   on ordinary devices, without asking anyone to install a VPN client first.
2. **The host itself should never be reachable from the internet.** Management
   interfaces, SSH, and the container runtime stay on a private path.
3. **Services should be disposable.** Any container should be able to be
   destroyed and recreated from its image with no loss of configuration or data.
4. **Storage layout should be predictable**, so that automation, backups, and
   filesystem behaviour (particularly hardlinks) stay consistent.
5. **Operations should be documented well enough to be repeatable**, including
   by a version of me who has not looked at the system for six months.

## Network model

The internet connection sits behind **CGNAT** (carrier-grade NAT). The ISP
shares one public address across many subscribers and translates connections at
the carrier's edge, so the router does not hold a routable public address of its
own. The practical consequence is that inbound port forwarding does not work:
there is no public address and port that can be pointed at the host, and no
router configuration on the customer side can create one.

The design therefore inverts the direction of the connection. Instead of waiting
for inbound traffic, the host runs a tunnel client that opens an **authenticated
outbound connection** to a cloud edge and keeps it open. Public requests arrive
at the provider's edge, are matched against a hostname-to-service ingress
ruleset, and are carried back down the existing outbound connection to the
container that should answer them.

This has a few properties worth stating explicitly:

- **No listening ports are published on the home connection.** The attack
  surface is the tunnel client's outbound session and whatever the ingress rules
  deliberately expose, not the perimeter of the network.
- **Exposure is per-route, not per-host.** A hostname only reaches a service if
  an ingress rule says so. Adding a container does not add public exposure.
- **Any hostname without a matching rule must fail closed.** The final ingress
  entry is a default deny that returns a 404, so unmatched or probing requests
  never fall through to an arbitrary internal service.

**Private administration takes a completely different path.** Administrative
access uses an **encrypted mesh VPN**: enrolled devices form a peer-to-peer
overlay with per-device identity, and the host administration interface and SSH
listen only on that overlay. None of it is published through the tunnel, so it
is not publicly routed and does not appear in DNS. Losing or retiring a device
is handled by revoking that device's identity rather than by rotating a shared
secret.

## Service flow

The media side of the lab is a pipeline rather than a collection of independent
apps. A request entered by a user moves through the stack like this:

```text
Request application
    -> automation service
    -> indexer abstraction
    -> isolated download client
    -> import and organisation
    -> subtitle processing
    -> media library scan and playback
```

Stage by stage:

- **Request application** — the only user-facing entry point for new content. It
  authenticates the requester and hands a structured request to automation.
- **Automation service** — decides whether the item is already held, what
  quality profile applies, and when to search.
- **Indexer abstraction** — a single internal endpoint in front of multiple
  sources, so credentials and source lists are configured once rather than in
  every downstream service.
- **Isolated download client** — performs the actual transfer. It runs with its
  own network path and is not exposed publicly.
- **Import and organisation** — moves completed items into the library layout,
  renames them to a consistent scheme, and links rather than copies where the
  filesystem allows it.
- **Subtitle processing** — fetches and matches subtitle tracks after import.
- **Library scan and playback** — the media service re-scans the affected path
  and the item becomes available to clients.

Each stage talks to the next over the container network by service name, so no
stage needs to know a host address, and only the request application and the
media service have public ingress rules.

## Storage conventions

All persistent state lives under one predictable root, split by purpose:

```text
/srv/
├── appdata/      # persistent service configuration and state
├── data/
│   ├── downloads/
│   └── media/
│       ├── movies/
│       └── tv/
├── backups/
└── system/
```

The rules behind the layout:

- **`appdata/` is per-service and small.** It holds databases, settings, and
  caches — the things that make a container *this* container. It is the primary
  backup target.
- **`data/` is the shared working tree.** Downloads and the finished library
  live under the same parent on purpose (see below).
- **`backups/` is a destination, not a source.** Nothing runs from it.
- **`system/` holds host-level and container-runtime state**, kept apart from
  application data so that a rebuild of one does not endanger the other.

### The hardlink rule

Downloads and media sit under one parent because **hardlinks only work within a
single filesystem, and containers can only link across paths they see as one
tree**. If a download client mounts `/srv/data/downloads` as `/downloads` and the
importer mounts `/srv/data/media` as `/media`, then from inside the containers
those are two unrelated roots: the import becomes a full copy, the data exists
twice, and capacity disappears quietly.

The fix is to map the **same host-level parent path, at the same container
path, in every service that participates**:

```text
Host            Container
/srv/data   ->  /data
                /data/downloads
                /data/media
```

Every container in the pipeline mounts `/srv/data` as `/data` and works with
`/data/downloads` and `/data/media` beneath it. Imports then become instant
hardlinks, a file can remain seeded while also being present in the library, and
one copy of the bytes is stored rather than two.

## Security boundaries

The system has three trust zones, and the boundaries between them are the point
of the whole design:

| Zone | Who reaches it | How |
|---|---|---|
| Public application surface | Anyone on the internet | Cloud edge → outbound tunnel → explicitly listed services only |
| Private administration | Enrolled devices only | Encrypted mesh VPN → host UI and SSH |
| Host and container runtime | Administrator, locally or over the mesh VPN | Never published publicly |

Supporting rules:

- **Default deny on the public side.** Unrecognised hostnames are answered with
  a 404 by the final ingress rule rather than being routed anywhere internal.
- **Least exposure per service.** A container is public only if a route names
  it; everything else is reachable only on the internal container network.
- **Authentication belongs to the application.** The tunnel proves where traffic
  goes, not who sent it, so public services carry their own authentication.
- **Secrets are never committed.** Tunnel tokens, VPN keys, and API credentials
  live in an ignored local `.env` file or a secrets manager; only placeholder
  examples are tracked.
- **Logs and screenshots are reviewed before publication.** Container logs
  routinely contain hostnames, addresses, tokens, and media titles, so nothing
  captured from the live system is published without being read line by line
  first.
