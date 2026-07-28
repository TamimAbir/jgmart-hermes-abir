# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `requirements.txt` and `.env.example`
- `docs/STATUS.md` — single source of truth for stage, location, and 30-day plan
- Foundation hardening pass (deps, honesty, geographic consistency)

### Changed
- README: correct clone URL (`TamimAbir/jgmart-hermes-abir`), honest pre-pilot status
- Business docs aligned to **Japan Garden City, Dhaka, BDT** (removed India/₹ confusion)
- EXECUTIVE_SUMMARY, BUSINESS_PLAN, FINANCIAL_MODEL rewritten for pilot realism

### Fixed
- Misleading investor-facing language that implied live traction

## [0.2.0] - 2026-07-28

### Added
- Professional repository restructure (v2.0)
- `.gitignore`, `LICENSE`, `CONTRIBUTING.md`, `README.md`
- `.github/` workflows, issue templates, PR template
- `docs/` hierarchy: audit, architecture, business, operations, api
- `src/`, `assets/`, `data/`, `config/`, `tests/` directories
- `ARCHIVE/` for legacy files
- Supabase schema + admin-new path

### Changed
- Reorganized ~295 files from flat numbered folders into semantic structure
- Moved Python scripts to `src/scripts/automation/`
- Moved web assets to `assets/` and `src/web/`

### Fixed
- Committed `__pycache__` removed from version control tracking
- Duplicate master indexes consolidated

### Security
- Plaintext data files audited and flagged in `BRUTAL_HONEST_AUDIT.md`
- Secrets management recommendations documented

## [0.1.0] - 2026-07-15

### Added
- Initial project structure with numbered folders (00–12)
- Business plan, pitch deck, financial model
- Web catalog, tech dashboard, marketing materials
- Operations playbooks and legal templates

---

**Note:** Earlier versions were tracked in `CHANGELOG.txt`. This file replaces the legacy changelog with a structured format.
