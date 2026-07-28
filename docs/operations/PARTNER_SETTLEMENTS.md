# Partner Settlement Ledger

**Status:** Schema ready (run migration)  
**Currency:** BDT (integer taka)  
**SQL:** `src/web/supabase/migrations/002_partner_settlement_ledger.sql`

---

## Why this exists

JG Mart collects money from customers. Partners must be paid for goods supplied, minus agreed commission. Delivery fees stay with JG Mart.

Without a ledger, settlements become WhatsApp arguments and spreadsheet drift.

---

## Money flow

```
Customer pays JG Mart
        │
        ├─ delivery fee     → JG Mart revenue
        └─ merchandise      → split
                ├─ commission %  → JG Mart
                └─ net           → Partner (ledger credit)

Later: payout (cash / bKash / bank) → ledger debit
```

**Net payable to partner (per order, simple model):**

```text
gross = sum(order_items.total) for that partner
commission = FLOOR(gross * partner.commission_rate)
net = gross - commission
```

---

## Tables

| Table | Purpose |
|-------|---------|
| `partner_ledger_entries` | Append-only ledger. Positive = we owe partner more. |
| `partner_settlements` | Period batch (e.g. weekly) with status workflow. |
| `partner_settlement_lines` | Which ledger credits are in a batch. |
| `partner_payouts` | Actual money sent to partner. |

Also:
- `order_items.partner_id` — attribute line to a partner (required for multi-partner baskets).
- Views: `partner_balances`, `partner_unsettled_credits`.

---

## Entry types

| Type | Sign | When |
|------|------|------|
| `sale_credit` | +net | Order fulfilled; partner owed |
| `commission` | usually − or informational | Optional if you split commission out |
| `payout` | −amount | Money paid to partner |
| `adjustment` | +/− | Disputes, spoilage, goodwill |
| `refund_clawback` | − | Reverse credit after late cancel/refund |
| `opening_balance` | +/− | Migrate prior spreadsheet balances |

Corrections = **new rows**, not edits.

---

## Settlement statuses

`open` → `pending_review` → `approved` → `partially_paid` / `paid`  
(`void` if cancelled)

Pilot tip: use `close_partner_settlement` weekly; review; then `record_partner_payout`.

---

## Core functions

### Post credit (idempotent per order+partner)

```sql
SELECT public.post_partner_sale_credit(
  '<order_uuid>',
  '<partner_uuid>'
  -- optional gross override,
  -- optional created_by profile uuid
);
```

Call when order reaches **delivered** (recommended). Safe to call twice — unique index prevents double credit.

### Close a period

```sql
SELECT public.close_partner_settlement(
  '<partner_uuid>',
  DATE '2026-07-21',
  DATE '2026-07-27',
  NULL,  -- created_by
  'Week 30 close'
);
```

Pulls unsettled `sale_credit` rows in the date range, attaches them to a new settlement, sets totals.

### Record payout

```sql
SELECT public.record_partner_payout(
  '<partner_uuid>',
  12500,           -- BDT
  'bkash',
  '<settlement_uuid>',
  'TRX-XXXX',
  'Weekly payout'
);
```

Writes payout row + negative ledger entry; updates settlement `amount_paid` / status.

### Balances

```sql
SELECT * FROM public.partner_balances ORDER BY balance_owed_bdt DESC;
SELECT * FROM public.partner_unsettled_credits;
```

---

## Ops SOP (pilot)

1. **On deliver** — ensure `order_items.partner_id` set; run `post_partner_sale_credit`.  
2. **Weekly** — `close_partner_settlement` per active partner.  
3. **Review** — compare settlement lines to WhatsApp/order log; mark `approved`.  
4. **Pay** — `record_partner_payout` with bKash/bank ref.  
5. **Reconcile** — `partner_balances` should match cash float notes.

---

## Multi-partner baskets

If one order sources rice from Partner A and fish from Partner B:

- Set `order_items.partner_id` per line.
- Call `post_partner_sale_credit` once per partner for that order.

If the whole order is one shop, one call with that `partner_id` is enough (fallback uses order `subtotal`).

---

## What this does not do yet

- Automatic trigger on `orders.status = delivered` (call from app/ops intentionally)
- Tax invoices / e-challan
- Partner self-serve payout requests
- Double-entry GL for full company books (this is a **partner sub-ledger** only)

---

## Install

1. Run `schema.sql` if not already.  
2. Run `migrations/002_partner_settlement_ledger.sql` in Supabase SQL Editor.  
3. Verify tables: `partner_ledger_entries`, `partner_settlements`, `partner_settlement_lines`, `partner_payouts`.  
4. Verify views: `partner_balances`.

---

*Keep float tight. Pay partners on a fixed cycle. Trust the ledger, not memory.*
