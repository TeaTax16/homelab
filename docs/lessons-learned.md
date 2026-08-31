# Lessons learned

The useful output of a homelab is not the running services — it is what breaks,
and what that forces you to understand.

## CGNAT changes the remote-access design

The initial assumption was that remote access is a router problem: forward a
port, point a DNS record at it, done. Behind CGNAT that route does not exist.
The public address is shared and translated at the carrier's edge, so there is
no address and port on the customer side to forward, and no amount of router
configuration creates one.

Once you accept that the connection can only be made **outbound**, the design
follows naturally: the host authenticates to a cloud edge, holds the connection
open, and the edge delivers public requests back down it. Selected services can
then be exposed without any conventional inbound port forwarding at all.

The side effect turned out to be better than the thing it replaced. Exposure
becomes a per-route decision rather than a property of the network perimeter,
and adding a container no longer changes what the outside world can reach.

## Public applications and host administration are different risks

It is tempting to treat "I can reach it from outside" as one capability. It is
two, and they deserve different answers.

A public application is something a person is meant to use: it has its own login
screen, its own permission model, and a blast radius bounded by what that
application can do. Host administration — the management UI, SSH, the container
runtime — is a different class entirely. Anything that reaches it can reach
everything, so it should not be exposed to the internet even behind a strong
password.

The split settled into: applications go through the tunnel with their own
authentication; administration stays on an encrypted mesh VPN, reachable only
from enrolled devices with per-device identity. Device revocation replaces
credential rotation, and the administrative surface simply is not on the public
internet to be scanned.

## Container paths affect filesystem behaviour

This was the most expensive lesson in terms of wasted capacity, and it looked
like an application bug for far longer than it should have.

Hardlinks only exist within a single filesystem, and a container can only link
across paths it sees as a single tree. Two containers can be given technically
correct mounts — one gets the downloads directory, another gets the media
directory — and every path resolves, every import succeeds, and every single
import is a full copy. Nothing errors. The disk just fills up twice as fast as
it should.

The fix is to treat mount layout as part of the filesystem design rather than
per-container plumbing: map the **same host parent path to the same container
path in every service in the pipeline**, and configure the applications to work
beneath it. Consistency across containers matters more than convenience within
any one of them.

## Disk monitoring needs an action plan

Collecting SMART data is easy, and by itself it accomplishes nothing. A warning
that produces no decision is the same as no monitoring at all.

What was missing was a predefined response. A warning now triggers a fixed
sequence: stop trusting the disk for important writes, verify that the data on
it actually restores from backup, plan and order the replacement, and track the
trend rather than the absolute value. Counters that climb mean an active
failure; counters that moved once and stopped mean a replacement can be
scheduled without drama.

The valuable part is deciding this in advance. Working it out while a disk is
degrading leads to the wrong order of operations — usually attempting a repair
before verifying the backup.

## Backups and redundancy solve different problems

Parity and redundancy protect against **a device failing**. They do nothing
against deletion, corruption that gets written through, a bad configuration
change applied everywhere at once, ransomware, or losing the whole machine. All
of those propagate happily across a redundant array.

A backup is a separate copy, off the server, that has been **tested by actually
restoring from it**. An untested backup is a belief, not a recovery plan, and
the moment it is needed is the worst possible time to discover it has been
silently writing zero-byte archives for a month.

The practical rule: redundancy keeps the service running through hardware
failure; backups are what get the data back. Both are needed, and only one of
them is verified by a parity check.

## Documentation is an operational tool

Notes written while a system is being built feel redundant — everything is
obvious at the time. Six months later, under pressure, with a service down and
no memory of why a particular path was chosen, they are the difference between a
ten-minute fix and an afternoon of re-derivation.

What proved worth writing down was small and specific: the diagnostic commands
in the order they should be run, the reason behind each non-obvious decision,
and the runbook for each failure that has already happened once. Not narrative,
not tutorials — just the things that are expensive to reconstruct.

Documentation also turned out to be a design check. Anything that could not be
explained clearly in a paragraph was usually something that had not been thought
through properly, and writing this repository forced several of those to be
tidied up before they could be described.
