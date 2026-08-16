---
name: own-infra-first
description: 'Use BEFORE proposing any new external tool, SaaS, hosting, database, automation platform or API for a project. Checks whether the already-paid environments (e.g. homelab, a VPS, shared hosting) cover the need. Triggers: "we need a database/hosting/automation/storage for this", "where should this go", "what service should we use for X", and when planning any new app/scraper/worker/cron — even if the user does not ask.'
---

# Own Infra First

The user works on already-paid, already-running environments — e.g. a **homelab**, a **VPS** at a
VPS provider, and **shared hosting**. For any new need, ALWAYS build on these first, and propose
a new external provider only when none of the existing ones fits — every new provider means
another monthly fee, another account and another maintenance surface, which fragments the system
over time.

This applies to every project, not just one.

> **Before putting anything live: run the `security-checklist` skill.**
> For a new service, port, container, database or tunnel it is a mandatory step —
> you may be handling customer data, and closing exposure after the fact is always more
> expensive.

## The data is not here

**The current inventory of the environments — what runs where, at what address, in what
version — lives in your shared data files** (e.g. `shared/shared_data_infrastructure.md` in your
docs git repo). This skill gives the *decision rule*, not the snapshot. Before naming a concrete
machine, port or service, read the data file — the `knowledge-base-map` skill tells you where it
is.

A rule of thumb that does not age: **if a capability already runs in one of the environments,
extend it — do not install a parallel one.** Typically already present: automation (n8n), git
(Gitea), password and secret management (your password manager, e.g. Vaultwarden), monitoring and
alerting (Grafana + Prometheus + Uptime Kuma), database, VPN (WireGuard), local LLM and image
generation (Ollama, ComfyUI), storage and backup (a NAS). So do **not** propose Zapier, Make.com,
a new GitHub organization, 1Password, Datadog, PagerDuty, a commercial VPN, a paid LLM API or
cloud storage while the existing capability can carry the load.

## Decision order for a new need

1. **Does the capability already exist?** If yes, use it — do not install a parallel one.
2. **If not, but it fits an existing machine or container** → extend there. By default the
   **homelab** is the first candidate; then the **VPS**, when a fixed, public, datacenter IP is
   needed; then the **shared hosting**, when provider-grade uptime or plain PHP/static serving is
   all that is required.
3. **If none fits** (technical limit, compliance, scale) → only then propose a new external
   provider, and **state explicitly why none of the existing environments is enough**.

## Three constraints that had to be learned

- **Scrapers and logged-in site reading cannot go on the VPS.** WAFs block known datacenter IP
  ranges — this needs a residential IP, i.e. the homelab. (E.g. two scrapers had to move back
  home for exactly this reason.)
- **Shared hosting's Python/WSGI support is uncertain.** It is PHP-oriented, with no root and no
  persistent background processes. Plan a Python-based app there only after verifying.
- **The homelab router sits behind CGNAT** — inbound connections do not get through, and DDNS
  solves nothing. Whatever must be reachable from outside goes out via a Cloudflare Tunnel, or
  onto the VPS.

## If it lands on the homelab and needs a container

A new LXC or VM on the cluster **will not be fault-tolerant by itself**: replication, the HA
resource, the affinity rule and the backup must all be wired up by hand. The
`proxmox-ha-new-guest` skill is the checklist for that.

## Example

Input: "We need something that sends yesterday's scraper errors to Telegram every morning."
Right direction: do not propose Make.com or Zapier. The homelab's n8n, or a simple cron following
the existing Telegram-bot pattern, is exactly for this — extend that.
