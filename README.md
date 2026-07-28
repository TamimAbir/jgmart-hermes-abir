# JG Mart Hermes

**JG Mart** is a hyperlocal grocery delivery service for **Japan Garden City (JGC), Dhaka, Bangladesh**.  
WhatsApp-first ordering, partner stores, short delivery slots.

This repository holds the technical, operational, and business foundation for the pilot.

## Status

> **Pre-seed / Pre-pilot.** Schema and tooling exist. Live traction is not yet recorded.  
> Read **[docs/STATUS.md](docs/STATUS.md)** first — single source of truth.

| Item | Value |
|------|--------|
| Stage | Pre-seed / Pilot preparation |
| Market | Japan Garden City, Dhaka |
| Currency | BDT (৳) |
| Stack | Vanilla HTML/JS + Supabase (Postgres + Auth) |
| License | MIT |

Catalog (static): deploy from `src/web/catalog/`  
Admin (new): deploy from `src/web/admin-new/` after Supabase setup

## Quick Start

```bash
git clone https://github.com/TamimAbir/jgmart-hermes-abir.git
cd jgmart-hermes-abir

pip install -r requirements.txt

# Optional: run validation toolkit
python tests/validate_toolkit.py
```

### Supabase (required for real admin / orders)

1. Create a project at https://supabase.com  
2. Run `src/web/supabase/schema.sql` then `seed.sql`  
3. Copy `.env.example` → `.env` and set URL + keys  
4. Update `src/web/supabase/config.js`  
5. See `docs/SUPABASE_SETUP.md`

## Repository Map

```
├── docs/STATUS.md          ← start here
├── docs/business/          Business plan, financials, executive summary
├── docs/operations/        SOPs and runbooks
├── docs/architecture/      System design
├── src/web/catalog/        Customer-facing catalog (PWA)
├── src/web/admin-new/      Supabase admin
├── src/web/dashboard/      Ops dashboards (legacy localStorage paths)
├── src/web/supabase/       Schema, seed, client config
├── src/scripts/automation/ Daily summary, sync, deploy helpers
├── assets/                 Brand, images, financial CSVs
├── data/                   Samples, exports, backups
├── ARCHIVE/                Frozen legacy / AI drafts — do not treat as live truth
└── tests/                  Validation toolkit
```

## Principles

1. Ship real orders before more documentation.  
2. ARCHIVE is historical. New truth lives in `docs/`.  
3. Never commit secrets. Use `.env`.  
4. Bangladesh / BDT / JGC is canonical.  
5. Prefer narrow working paths over perfect architecture.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Open issues for bugs, features, or investor inquiries (templates under `.github/ISSUE_TEMPLATE/`).

## License

MIT — see [LICENSE](LICENSE).

---

*Built for Japan Garden City. Optimized for execution, not theater.*
