# Contributing to JG Mart Hermes

Thank you for your interest. Read **[docs/STATUS.md](docs/STATUS.md)** before anything else — it is the single source of truth for stage, location, and priorities.

## Code of Conduct
Be respectful. This project serves a real community (Japan Garden City, Dhaka). Harassment or unprofessional behavior will not be tolerated.

## How to Contribute

### 1. Fork & Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Priorities (what actually helps)
1. Making catalog + Supabase admin work end-to-end
2. Real order-path bugs and UX friction
3. Tests for pricing, order status, and data validation
4. Removing dead localStorage admin paths
5. Documentation only when it reflects **live** behavior

Avoid expanding ARCHIVE or adding more speculative playbooks.

### 3. Code Standards
- **Python:** PEP 8; prefer `black` + `flake8`
- **JavaScript / HTML:** Keep it simple and readable; prefer progressive enhancement
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat: ...`
  - `fix: ...`
  - `docs: ...`

### 4. Testing
```bash
pip install -r requirements.txt
python tests/validate_toolkit.py
# Add real pytest cases under tests/ when you change business logic
```

### 5. Documentation
- Update `docs/STATUS.md` if stage or priorities change
- Update `CHANGELOG.md` for user-facing changes
- Business docs must use **Bangladesh / BDT / JGC** language

### 6. Pull Requests
- Use the PR template
- Link related issues
- One focused change per PR

## Reporting Issues
Use bug / feature / investor inquiry templates under `.github/ISSUE_TEMPLATE/`.

## Security
Report vulnerabilities privately. Do not open public issues for security flaws. Do not commit secrets — use `.env` from `.env.example`.

## License
By contributing, you agree your code will be licensed under the MIT License.
