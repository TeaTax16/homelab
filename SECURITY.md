# Security

## This repository is sanitised

> This repository contains sanitised documentation and example configuration
> only. It deliberately excludes live credentials, real hostnames, IP addresses,
> domains, tunnel identifiers, media, user data, and production configuration
> exports.

Everything here describes design and operational practice in general terms. No
file in this repository is copied from, exported from, or directly usable
against the running system it describes.

## Never published here

The following are deliberately excluded and must never be committed:

- Real domains, subdomains, URLs, or DNS records.
- Public IP addresses, LAN or private addresses, and hostnames.
- Mesh VPN identities, node names, tailnet names, or overlay addresses.
- Tunnel identifiers, tunnel tokens, VPN or WireGuard keys, API keys, and
  credentials JSON files.
- Passwords, session cookies, SSH keys, and certificates.
- Any real `.env` file.
- Router, firewall, Cloudflare, Unraid, Docker, or VPN configuration exports
  from the live system.
- Full `docker inspect` output, or compose files copied from the live host.
- User data, backups, appdata, database dumps, and media titles or listings.
- Raw logs of any kind.
- Screenshots containing identifiable metadata, addresses, or content.
- Details that reveal the live system's exact exposure, such as real routing
  tables, port maps, or public service endpoints.
- Material owned by an employer, organisation, client, university, or other
  third party.

## Handling secrets

- Keep secrets in a local `.env` file that is ignored by Git, or in a dedicated
  secrets manager. Only `examples/.env.example` — placeholders only — is
  tracked.
- Inject values into containers by environment reference (`${TUNNEL_TOKEN}`),
  never inline in a tracked file.
- Treat logs and screenshots as secret-bearing by default. Read them fully
  before sharing any excerpt.
- Before committing, search the staged diff for token-shaped strings, addresses,
  email addresses, and real hostnames.

## Reporting a problem

If you believe this repository exposes sensitive information, or you find a
security issue in something described here:

- **Do not open a public issue containing the secret or the details.** A public
  report republishes the exact thing that needs removing.
- Contact the repository owner privately through their GitHub profile.
- If a credential has been exposed anywhere, **rotate it immediately** —
  revoking and reissuing comes first, and cleaning up the record comes second.
  Assume anything that reached a public repository has already been collected.
