# JG Mart Hermes — common commands
# Usage: make <target>

.PHONY: help install validate lint status catalog-serve admin-hint

help:
	@echo "JG Mart Hermes"
	@echo "  make install     - pip install -r requirements.txt"
	@echo "  make validate    - run validation toolkit"
	@echo "  make lint        - black + flake8 (soft)"
	@echo "  make status      - print path to STATUS.md"
	@echo "  make catalog-serve - serve catalog on :8080 (python http.server)"

install:
	pip install -r requirements.txt

validate:
	python tests/validate_toolkit.py

lint:
	black --check src/ tests/ || true
	flake8 src/ tests/ --max-line-length=88 --extend-ignore=E501,W503 || true

status:
	@echo "Read: docs/STATUS.md"

catalog-serve:
	cd src/web/catalog && python -m http.server 8080

admin-hint:
	@echo "1. Create Supabase project"
	@echo "2. Run src/web/supabase/schema.sql and seed.sql"
	@echo "3. Copy .env.example -> .env and fill keys"
	@echo "4. Update src/web/supabase/config.js"
	@echo "5. Deploy src/web/admin-new/"
