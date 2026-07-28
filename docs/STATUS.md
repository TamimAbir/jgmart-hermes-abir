# JG Mart Hermes — Project Status

**Last updated:** 2026-07-28  
**Stage:** Pre-seed / Pre-pilot  
**Location:** Japan Garden City (JGC), Dhaka, Bangladesh  
**Currency:** BDT (৳)

---

## One-Sentence Summary

Hyperlocal grocery delivery for Japan Garden City residents — WhatsApp-first ordering, partner stores, short-slot rider delivery.

---

## What Exists Today

| Layer | Status | Notes |
|-------|--------|-------|
| Web Catalog (PWA) | Partial | Static HTML/JS, product data, WhatsApp order handoff |
| Admin Panel | Partial | Supabase-backed admin in `src/web/admin-new/` |
| Database core | Schema ready | `schema.sql` + `seed.sql` |
| **Partner settlements** | **Schema ready** | `migrations/002_partner_settlement_ledger.sql` + ops doc |
| Auth | Designed | Supabase Auth + roles |
| Automation Scripts | Usable | Daily summary, sync bridge, validation toolkit |
| Ops Playbooks | Extensive | ARCHIVE frozen; live docs under `docs/` |
| Live Traction | None | Zero real orders recorded in repo |

---

## Partner money (new)

Ledger model shipped:

- `partner_ledger_entries` — append-only sub-ledger  
- `partner_settlements` + lines — weekly (or custom) batches  
- `partner_payouts` — cash / bKash / bank  
- Functions: `post_partner_sale_credit`, `close_partner_settlement`, `record_partner_payout`  
- Views: `partner_balances`, `partner_unsettled_credits`  

Runbook: **[docs/operations/PARTNER_SETTLEMENTS.md](operations/PARTNER_SETTLEMENTS.md)**

---

## Critical Truths (No Spin)

1. Toolkit + static frontend, not a scaled multi-city platform.
2. Unit economics are paper until real orders exist.
3. Canonical market: **Japan Garden City, Dhaka, BDT**.
4. ARCHIVE is historical, not live truth.
5. Settlement SQL is ready; **ops process must call the functions** (no auto-trigger yet).

---

## Next 30 Days (Recommended Sequence)

### Week 1 — Make it runnable
- [ ] Supabase project; run `schema.sql` → `seed.sql` → `migrations/002_...sql`
- [ ] `.env` + `config.js`; admin login works
- [ ] Kill remaining localStorage-only admin paths for daily use

### Week 2 — One real order cycle
- [ ] 2–3 JGC partners onboarded; `partners` rows + commission rates
- [ ] 10 real orders; set `order_items.partner_id`
- [ ] On deliver: `post_partner_sale_credit`
- [ ] Track real AOV / on-time % / cancellations

### Week 3 — First settlement cycle
- [ ] `close_partner_settlement` for each partner
- [ ] Review + `record_partner_payout`
- [ ] Reconcile `partner_balances` vs cash float

### Week 4 — Pilot decision
- [ ] Live contribution margin vs paper model
- [ ] Expand, iterate, or pause

---

## Repo Hygiene Rules

1. **One status file:** this document.  
2. **ARCHIVE is frozen.**  
3. **No secrets in git.**  
4. **Bangladesh / BDT / JGC** in business language.  
5. Prefer working software + real payouts over more decks.

---

*Ship orders. Pay partners on a fixed cycle. Trust the ledger.*
