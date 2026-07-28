# Sample datasets — JG Mart

Realistic **synthetic** data for Japan Garden City (Dhaka) pilot demos.

| File | Use |
|------|-----|
| `jgc_pilot_demo.json` | Full demo: partners, customers, line-item orders, settlement illustration |
| `sample_data.json` | Dashboard-friendly orders/customers/partners/inventory |
| `test_data.json` | Lightweight fixture (legacy tests) |

## Catalog images

Local category tiles live in `src/web/catalog/images/cat_*.svg`.  
`src/web/catalog/db.js` maps every product to its category tile so the site does not depend on Unsplash.

## Supabase partners

```text
src/web/supabase/seed_partners_sample.sql
```

Run after `schema.sql`.

## Important

These are **not** real customers. Replace phone numbers before any production messaging.
