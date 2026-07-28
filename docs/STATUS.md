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
| Admin Panel | Partial | New Supabase-backed admin in `src/web/admin-new/`; old localStorage admin deprecated |
| Database | Schema ready | `src/web/supabase/schema.sql` + seed — not yet live-connected in all pages |
| Auth | Designed | Supabase Auth + roles (customer/operator/admin/partner) |
| Automation Scripts | Usable | Daily summary, sync bridge, image helpers, validation toolkit |
| Ops Playbooks | Extensive | ARCHIVE + docs/operations — treat ARCHIVE as historical |
| Live Traction | None | Zero real orders / partners / NPS recorded in repo |

---

## Critical Truths (No Spin)

1. This is a **founder toolkit + static frontend**, not a production multi-tenant platform.
2. Unit economics and projections exist on paper only.
3. Geographic/currency language was previously mixed (India/₹ vs BD/৳). **Canonical is Japan Garden City, Dhaka, BDT.**
4. CI exists but tests are soft (`|| echo 'No tests yet'`). Treat as hygiene, not quality gate.
5. ARCHIVE contains large volumes of AI-generated drafts. Do not treat it as living source of truth.

---

## Next 30 Days (Recommended Sequence)

### Week 1 — Make it runnable
- [ ] Create real Supabase project; run `schema.sql` + `seed.sql`
- [ ] Put real keys in local `.env` (never commit)
- [ ] Wire `src/web/supabase/config.js` and verify catalog + admin against live DB
- [ ] Delete or redirect every remaining localStorage admin path

### Week 2 — One real order cycle
- [ ] Onboard 2–3 partner stores in JGC
- [ ] Process 10 real orders end-to-end (catalog → WhatsApp → rider → delivered)
- [ ] Record actual AOV, delivery time, cancellations in a simple sheet

### Week 3 — Harden the minimum path
- [ ] Add pytest for order creation / status transitions
- [ ] Make CI fail on real test failures
- [ ] Optimize product images; remove duplicates

### Week 4 — Pilot decision
- [ ] Review real unit economics vs model
- [ ] Decide: expand pilot or pause and rebuild backend

---

## Repo Hygiene Rules

1. **One status file:** This document. Update it when stage changes.
2. **ARCHIVE is frozen.** New docs go in `docs/`.
3. **No secrets in git.** Use `.env` + `.env.example` only.
4. **Bangladesh / BDT / JGC** in all new business language.
5. Prefer working software over more playbooks.

---

## Owners

- Repo: TamimAbir
- Parallel work: brother may maintain a separate fork — keep this repo as the structured source of truth.

---

*Ship orders. Everything else is secondary.*
