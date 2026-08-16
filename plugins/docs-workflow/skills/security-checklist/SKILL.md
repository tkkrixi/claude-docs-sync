---
name: security-checklist
description: 'MANDATORY security checklist for EVERY infrastructure change — new worker, VPS, container, database, tunnel, VPN, service, port, DNS record, wifi, user, key, cron, backup, network device. Run it even if the user does not ask, and even when the change is "just a small thing" — you may be handling customer data. Triggers: "install", "create", "open up", "expose", "new CT/VPS/DB/tunnel/SSID/user", any new service or port, and before any go-live.'
---

# Security checklist — for every change

**Default stance: closed.** A new service should be reachable from nowhere by default; we open
from where the need is proven. You may be handling customer data — "we'll lock it down later" is
not an option.

## 1. Exposure — what can see it from outside?

- **Public port only when unavoidable.** Databases, admin UIs and monitoring never go on the open
  internet. If two machines must reach each other, that is a **WireGuard tunnel**, not an open
  port.
- **Bind address:** `127.0.0.1` or the tunnel address, not `0.0.0.0`. With Docker, also in the
  port mapping (`127.0.0.1:9090:9090`) — otherwise the container bypasses the host firewall.
- **Firewall:** default-drop, allow only from named sources. After adding a rule, **check the
  order** — it must land before the drop at the end of the chain.
- **On shared hosting you cannot filter.** If the provider runs you behind a proxy (the server
  sees you from an internal address), user/host restrictions are impossible in principle, and you
  have no GRANT rights either. The only fix then is **moving it to your own infrastructure**.
- A new public hostname goes behind **Cloudflare Access** (or equivalent), unless there is an
  explicit reason not to.

## 2. Authentication and secrets

- Factory/default passwords are changed **immediately** — on devices too (printer, AP, switch,
  NVR).
- Key-based SSH, password login disabled, `PermitRootLogin prohibit-password`.
- DB users are **host-bound** (`user@10.8.0.2`) with the narrowest rights — a scraper must not be
  able to run DDL.
- **Secrets never go into chat, docs, or a repo.** Generate into a file (`chmod 600`) on the
  user's machine, move it into your password manager (e.g. Vaultwarden), then delete the file.
  Pass passwords via a file or shell variable, not on the command line — `ps` sees it.
- `.env` is always `600`, and in `.gitignore`.

## 3. Brute force and attack surface

- A public login gets rate-limiting (nginx `limit_req`) **and** a fail2ban jail. fail2ban only
  watches SSH by default — a web login needs its own jail.
- Systems with customer accounts also need **account-level lockout**: IP-based protection cannot
  see a slow attack coming from many addresses.

## 4. Backup and restore

- New data → an **immediate** backup plan: where to, how often, retained how long.
- Do **not** judge backup success by the exit code: did the file actually arrive at the target?
  Is it intact (`gzip -t`)? Complete (the dump's closing line is present)? A silent NAS-mount
  failure once sent days of "successful" backups to the local disk.
- Monthly **restore test**. A backup is only a backup if it can be loaded back.

## 5. Does it survive a reboot?

- `systemctl is-enabled` for every new service.
- If a service binds to a tunnel or virtual address, wire the unit ordering by hand
  (`After=`/`Wants=`), plus `ip_nonlocal_bind` as a safety net.
- On macOS use a `LaunchDaemon`, **never** a `LaunchAgent` — the latter only starts after a
  graphical login.
- Where possible, prove it with a **real reboot test**. This has exposed silent failures more
  than once.

## 6. Monitoring

- New service → an Uptime Kuma monitor and/or Prometheus target, with an alert (e.g. Telegram).
- Monitoring through a tunnel measures the service and the tunnel at once — that is a feature.

---

## Measurement discipline — where this has slipped before

**Negative claims only from a valid probe.** Before declaring "it is unreachable" or "the
password no longer works", run a control:

- **with a wrong password** — if that also "succeeds", the probe is not about the password;
- **without authentication** — if you still get a 200, you are measuring a public page (some
  devices' status pages behave like this);
- an explicit `-i key` **narrows** the SSH client's offer — it does not follow that the device
  has no key installed.

**IPv4 and IPv6 separately.** An IP-based allowance (access bypass, whitelist, firewall rule)
stays silently ineffective if the client goes out over v6:
`curl -o /dev/null -w '%{remote_ip}' https://<host>`

**Layers mislead.** An empty `Ssl_cipher` does not mean no encryption — TLS may terminate at the
provider's proxy. Verify at socket level, not from the server's status variables.

## Before a risky step

1. **Backup** (`/export`, `cp -a`, dump) — always, and note where it went.
2. Is there a **self-restore**? On network gear, a timed rollback; on a switch, do not save the
   `startup-config` until the change is proven working.
3. **What does it take down if it breaks?** E.g. before switch maintenance under a Proxmox
   cluster, set the HA resources to `ignored`.
4. **Irreversible deletions are performed by the user**, not you. Your part is the verified
   backup and the after-the-fact proof.

## Output

After the change, into the log: **what was exposed, what protects it, how you verified it.** What
you could not verify, say so — do not dress uncertainty up as confidence.
