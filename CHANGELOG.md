# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Partner settlement ledger migration: `src/web/supabase/migrations/002_partner_settlement_ledger.sql`
  - Tables: `partner_ledger_entries`, `partner_settlements`, `partner_settlement_lines`, `partner_payouts`
  - Views: `partner_balances`, `partner_unsettled_credits`
  - Functions: `post_partner_sale_credit`, `close_partner_settlement`, `record_partner_payout`, `decrement_stock_for_order`
  - Safer `generate_order_number()` via sequence
  - `order_items.partner_id` for multi-partner baskets
- Ops guide: `docs/operations/PARTNER_SETTLEMENTS.md`
- `requirements.txt`, `.env.example`, `Makefile`, `docs/STATUS.md`

### Changed
- Business docs aligned to Japan Garden City, Dhaka, BDT
- README clone URL and honest pre-pilot status
- Supabase setup guide includes migration 002
- `auto_deploy.py` paths fixed for post-restructure layout

## [0.2.0] - 2026-07-28

### Added
- Professional repository restructure (v2.0)
- GitHub standards, docs hierarchy, Supabase schema + admin-new

### Changed
- Reorganized files from numbered folders into semantic structure

## [0.1.0] - 2026-07-15

### Added
- Initial toolkit structure, business and ops materials

---

**Note:** Legacy notes lived in `CHANGELOG.txt`; this file is canonical.
