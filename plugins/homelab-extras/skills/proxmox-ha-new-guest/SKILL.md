---
name: proxmox-ha-new-guest
description: 'Use when creating a new LXC/VM on a Proxmox cluster, migrating one, putting one under HA/replication, or giving a container a bind mount (mp0). Proxmox HA/pvesr is NOT automatic — it must be wired up by hand; a bind mount blocks pvesr and must be avoided in HA-capable containers. Triggers: "new container on the cluster", "put it under HA", "set up replication", "need a mount / mp0", planning any new CT/guest.'
---

# Proxmox HA — new CT/guest checklist

This checklist makes sure a new guest on your cluster (e.g. three nodes: <node-a>, <node-b>,
<node-c>) actually **survives a node failure**, not just starts. The storage model it assumes:
**local ZFS + `pvesr` replication + HA** (no shared storage). Every step follows from that.

> **Before putting anything live: run the `security-checklist` skill.**
> For a new service, port, container, database or tunnel it is a mandatory step —
> you may be handling customer data, and closing exposure after the fact is always more
> expensive.

## The most important thing to know

**Nothing is automatic.** Being on the cluster does NOT mean a guest fails over by itself on a
node outage. **Four** things must be wired up by hand for every new guest:

1. **`pvesr` replication** — to **both other nodes**, two jobs per guest. With a single
   replication target only one specific node could take over; with two, any surviving node can.
2. **HA resource** (`ha-manager add`) — this is what turns on actual automatic failover with
   fencing.
3. **Node-affinity rule** — without it the CRM may move the guest to a node that has no replica,
   and the start fails with `dataset does not exist`. This has happened in production.
4. **Backup** — add the guest to the vzdump job's `vmid` list, **and force the first backup by
   hand**.

If any of these is missing, the guest simply sits stopped on a node outage until someone starts
it elsewhere by hand — or it does not start at all.

## BIND-MOUNT PITFALL — read before adding mp0

`pvesr` **cannot replicate a bind mount**, and if a container has one (`mp0: /host/path`), it
**rejects the whole replication job**: `unable to replicate mountpoint type 'bind'`. The
`replicate=0` flag does NOT help (it only affects volume mountpoints).

**Consequence:** an HA-capable container must have **no bind mounts.** If the container needs a
host folder (e.g. a NAS share), do not hand it in as a bind mount — let the container **mount it
itself** with the `mount=cifs` (or `mount=nfs`) feature from its own `/etc/fstab`. That way the
share is reachable on any node, and `pvesr` is not blocked. (One of our containers hit exactly
this: its `mp0 /mnt/nas` was redundant because the container already mounted the share itself via
`mount=cifs` — the `mp0` was deleted.)

If you delete an mp0 from a running container: the deletion stays **pending**, because the
running container holds the mount — a **restart** is needed before `pvesr` accepts it.

## Step by step — wiring a new CT into HA

Assuming the CT is already running on the cluster on local ZFS storage, `<VMID>` is the container
id, and `<node-b>` / `<node-c>` are the replication targets.

**0. Check there is no bind mount** (if there is, resolve it first as above):

```bash
pct config <VMID> | grep -E '^mp[0-9]+' | grep bind && echo "BIND MOUNT PRESENT — fix it first!"
```

**1. Replication to BOTH other nodes** (every 5 minutes):

```bash
pvesr create-local-job <VMID>-0 <node-b> --schedule "*/5"
pvesr create-local-job <VMID>-1 <node-c> --schedule "*/5"
pvesr status | grep "^<VMID>-"    # wait until both are OK (LastSync fills in)
```

**2. HA resource** (this turns on the failover):

```bash
ha-manager add ct:<VMID> --state started
ha-manager status | grep -E "ct:<VMID>|fencing"   # expect 'started' + 'fencing armed'
```

**3. Node-affinity rule** — the guest's primary node gets the highest priority, the other two get
a lower one because of the replicas.

```bash
ha-manager rules config              # inspect the existing rules' format and add yours the same way
```

## Backup for the new guest

- **Native vzdump job** (Datacenter → Backup): add `<VMID>` to the existing cluster job
  (e.g. snapshot mode, zstd, `keep-daily=7,keep-weekly=4`). The cluster scheduler runs it on the
  guest's current node, so it is HA-aware.
- **Force the first backup by hand**, otherwise the guest stays unbacked until the next scheduled
  run — and it goes unnoticed, because the `vmid` is right there in the job list:
  ```bash
  vzdump <VMID> --storage <backup-storage> --mode snapshot --compress zstd
  ls -l /mnt/pve/<backup-storage>/dump/ | grep <VMID>
  ```
- **If you write a host-side backup script**, put an **HA guard** at the top so it only runs on
  the node currently hosting the guest:
  ```bash
  pct list 2>/dev/null | awk '{print $1}' | grep -qx <VMID> || exit 0
  ```
  And install the script **on all nodes** via cron.

## Final verification

```bash
pvesr status                              # the <VMID>-0 job shows State=OK
ha-manager status | grep ct:<VMID>        # started
```

Real test (optional, carefully): with a non-critical guest, power off the node it runs on and
watch whether HA starts it on a neighbor after fencing.

## Pitfalls (learned the hard way)

- **Bind mount → no replication.** (See above — the most common blocker.)
- **The first `pvesr` sync is full** (it sends the whole rootfs); on 1 Gbit with `zstd` it can
  take minutes, and it is slower still when two guests replicate in opposite directions in
  parallel. `LastSync` stays "-" until the first run finishes — that is normal, not an error.
- **`pvesr` and HA decide from the config**, not from the running state: after a config change
  (e.g. deleting mp0) a restart is needed for it to take effect.
- **HA does not solve everything:** it does not guarantee the application's external dependencies
  (e.g. an embedding service running on another host) — failover starts the container; the rest
  depends on the network and external services.
