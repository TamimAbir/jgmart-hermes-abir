# JG Mart — Supabase Setup Guide

> **Last Updated:** 28 July 2026  
> **Repo:** https://github.com/TamimAbir/jgmart-hermes-abir  
> **Region tip:** Asia Pacific (Singapore)

---

## 1. Create project

1. https://supabase.com → New project  
2. Name e.g. `jgmart-db`  
3. Save database password  
4. Region: Singapore (or closest available)  
5. Copy **Project URL** + **anon key** (+ keep **service_role** secret)

---

## 2. Run SQL (order matters)

In **SQL Editor**:

| Step | File |
|------|------|
| 1 | `src/web/supabase/schema.sql` |
| 2 | `src/web/supabase/seed.sql` |
| 3 | `src/web/supabase/migrations/002_partner_settlement_ledger.sql` |

### Tables after step 1–2

profiles, categories, products, orders, order_items, customers, partners, settings, audit_log

### Tables after step 3 (settlements)

partner_ledger_entries, partner_settlements, partner_settlement_lines, partner_payouts  
Views: `partner_balances`, `partner_unsettled_credits`  
Also: `order_items.partner_id`, safer `generate_order_number()`

Details: **[docs/operations/PARTNER_SETTLEMENTS.md](operations/PARTNER_SETTLEMENTS.md)**

---

## 3. Auth

1. Authentication → Providers → Email enabled  
2. Create admin user (Auto Confirm for pilot)  
3. Set `profiles.role = 'admin'` for that user UUID

---

## 4. App config

```bash
cp .env.example .env
# set SUPABASE_URL and keys
```

Update `src/web/supabase/config.js` with project URL + anon key.

Never commit `.env` or `service_role`.

---

## 5. Verify

- [ ] Table Editor shows core + settlement tables  
- [ ] Categories/products seeded  
- [ ] Admin can sign in  
- [ ] `SELECT * FROM partner_balances;` runs  
- [ ] Catalog/admin pointed at live project

---

## 6. Settlement smoke test

```sql
-- After you have a real partner + delivered order:
-- SELECT public.post_partner_sale_credit('<order_id>', '<partner_id>');
-- SELECT * FROM partner_balances;
```

---

## Troubleshooting

| Symptom | Check |
|---------|--------|
| RLS violation | Logged-in role in `profiles` |
| Missing tables | Re-run schema + migration 002 |
| Invalid API key | Use **anon** key in browser apps |
| Double partner credit | Unique index on sale_credit(order, partner) |

---

## Support

- Status: `docs/STATUS.md`  
- Settlements: `docs/operations/PARTNER_SETTLEMENTS.md`  
- WhatsApp (business config): +8801870489448

---

*JG Mart — Japan Garden City, Dhaka*
