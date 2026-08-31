# Operations

The stack runs Docker on Unraid, with Cloudflare Tunnel for public ingress and
Tailscale for private administration. Everything below is written with generic
container names and paths — substitute your own container names, mount points,
and device nodes locally. None of the real values are recorded here.

## Container diagnostics

Start with what is actually running, and what is not:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

The second command is the important one during an incident: a container that has
exited or is in a restart loop is invisible to the first. A `Status` column that
reads "Restarting" repeatedly usually means a bad configuration file, a missing
mount, or a permissions problem rather than a crash in the application.

Then read the logs:

```bash
docker logs --tail 100 <container-name>
docker logs -f <container-name>
```

The tail gives the state at failure; the follow shows what happens on the next
attempt. For a restart loop, start the follow and then restart the container so
the whole startup sequence is captured.

## Inspecting mounts

Most "the file is not where the app thinks it is" problems are mount problems.
This walks every running container and prints its host-to-container mappings:

```bash
for c in $(docker ps --format '{{.Names}}'); do
  echo "===== $c ====="
  docker inspect --format '{{range .Mounts}}{{println .Source " -> " .Destination}}{{end}}' "$c"
done
```

Read the output as a set, not one container at a time. Every service in the same
pipeline should show the *same host source path* mapped to the *same container
destination*. A service that maps a subdirectory where its neighbours map the
parent is the classic cause of copies instead of hardlinks.

## Storage checks

```bash
du -sh /srv/appdata /srv/data /srv/backups /srv/system
find /srv -maxdepth 3 -type d -print | sort
```

The first command answers "where did the capacity go" at the top level; the
second shows whether the directory tree still matches the intended convention.
Unexpected directories at depth two or three are usually a container that was
given a slightly wrong mount and quietly created its own path.

Disk health is checked per device:

```bash
smartctl -a /dev/sdX
```

Read the reallocated-sector, pending-sector, and offline-uncorrectable counters,
and the error log. A non-zero and *rising* pending-sector count matters far more
than a single non-zero value that has never moved.

## Tunnel and VPN checks

```bash
docker logs --tail 100 <tunnel-container>
docker logs <tunnel-container> 2>&1 | grep -i error
tailscale status
```

A healthy tunnel client logs a registered connection to one or more edge
locations and then goes quiet. Repeated re-registration means an unstable
upstream link. Ingress errors that name a service usually mean the container
name or port in the ingress rules no longer matches reality.

`tailscale status` should list the enrolled peers and show a direct connection
rather than a relayed one for devices on the same network. Relayed connections
still work but are slower — worth noticing, not worth an incident.

## Maintenance schedule

### Weekly

- Check that every expected container is running and none are restarting.
- Skim tunnel client logs for repeated errors.
- Check free capacity on the data and appdata paths.
- Confirm the public request and media routes answer from an external network.

### Monthly

- Update container images, one service group at a time, and verify each group
  before moving on.
- Review SMART attributes on every disk and compare against last month's values.
- Verify that the most recent backup exists, is the expected size, and that at
  least one file restores from it.
- Prune unused images and volumes to recover space.
- Review mesh VPN device list and remove devices no longer in use.

### Quarterly

- Perform a full parity or integrity check on the array.
- Do a real restore test: recover a service's `appdata` into a scratch location
  and start it, rather than assuming the archive is good.
- Review public ingress rules and remove anything no longer needed.
- Rotate the tunnel token and any API credentials.
- Re-read this documentation and correct whatever has drifted.

## Runbook: a public service stops responding

Work outward from the container, because the fault is far more often local than
upstream.

1. **Is the container running?** `docker ps -a` — if it has exited, the logs
   from the failed run explain why.
2. **Does it answer internally?** Reach it over the mesh VPN on its internal
   address and port. If it answers here but not publicly, the fault is in
   routing, not the application.
3. **Is the tunnel client connected?** Check its logs for registration and for
   errors naming the affected route.
4. **Do the ingress rules still match?** A renamed container or a changed
   internal port breaks the rule silently; the edge returns an error while the
   service itself is perfectly healthy.
5. **Is it the whole connection?** If every route is down at once and the tunnel
   client cannot register, the problem is the internet link or the provider's
   edge, not the lab.

A public route returning 404 for a hostname that used to work almost always
means the request is falling through to the default deny rule — the rule for
that hostname is missing, misspelled, or was lost in an edit.

## Runbook: imports are copying instead of hardlinking

Symptom: capacity drops by roughly twice the size of each imported item, and
imports take as long as a file copy instead of completing instantly.

1. Dump the mount mappings for the download client and the importing service
   using the loop above.
2. Compare the **host source paths**. If one mounts the downloads directory and
   the other mounts the media directory, they are on separate trees as far as
   the containers are concerned, and a link is impossible.
3. Confirm both paths are genuinely on the same filesystem on the host; a link
   cannot cross filesystem boundaries no matter how the mounts are arranged.
4. Fix by mapping the shared parent — host `/srv/data` to container `/data` — in
   every service in the pipeline, and updating each application's configured
   paths to sit beneath it.
5. Re-run one import and confirm the free space does not drop by the item size.

## Runbook: responding to SMART errors

A SMART warning is a scheduling problem, not an emergency, but it is also not
something to acknowledge and forget.

1. **Capture the full report** for the affected device and note which attributes
   changed and by how much.
2. **Stop trusting the disk for important writes.** Move anything irreplaceable
   off it and stop directing new writes to it.
3. **Verify recovery before touching anything.** Confirm the backup of the data
   on that disk exists and actually restores. This comes before any repair
   attempt.
4. **Plan the replacement.** Order the drive; do not wait for the next warning.
5. **Watch the trend, not the number.** Re-check the same attributes on a short
   interval. Counters that keep climbing mean the disk is actively failing;
   counters that stay flat mean a replacement can be scheduled calmly.
6. **After replacement**, rebuild, then re-verify the array and the backups
   before considering the incident closed.
