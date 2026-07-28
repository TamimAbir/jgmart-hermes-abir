-- ============================================
-- JG Mart — Partner Settlement Ledger (v1)
-- Run AFTER schema.sql (+ seed.sql optional)
-- Currency: BDT integers (taka, no decimals)
-- Market: Japan Garden City, Dhaka
-- ============================================
--
-- Mental model
-- -----------
-- Customer pays JG Mart (cash / bKash / etc.).
-- Partner is owed: product subtotal attributable to them
--   minus commission (default partners.commission_rate).
-- Delivery fee stays with JG Mart (not partner liability).
--
-- partner_ledger_entries is append-only style accounting.
--   amount_signed > 0  => credit to partner (we owe more)
--   amount_signed < 0  => debit (payout, clawback, commission already netted in sale_credit)
--
-- Settlements group unpaid credits into a period batch.
-- Payouts record real money leaving the float to the partner.
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- --------------------------------------------
-- 0. Safer order numbers (sequence)
-- --------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT AS $$
DECLARE
  n BIGINT;
BEGIN
  n := nextval('public.order_number_seq');
  RETURN 'JG-' || LPAD(n::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- --------------------------------------------
-- 1. Partner ledger (source of truth for balance)
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS public.partner_ledger_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE RESTRICT,
  entry_type TEXT NOT NULL CHECK (entry_type IN (
    'sale_credit',      -- delivered order: net amount owed to partner
    'commission',       -- optional explicit commission line (if not netted in sale_credit)
    'adjustment',       -- manual fix (spoilage, price dispute)
    'payout',           -- money paid to partner
    'refund_clawback',  -- reverse prior credit after refund/cancel post-settle
    'opening_balance'   -- one-time seed
  )),
  -- Signed amount in BDT (integer taka):
  --   positive = increases what we owe the partner
  --   negative = decreases what we owe (payouts, clawbacks)
  amount_signed INTEGER NOT NULL CHECK (amount_signed <> 0),
  -- Gross merchandise portion (before commission), when applicable
  gross_amount INTEGER CHECK (gross_amount IS NULL OR gross_amount >= 0),
  commission_amount INTEGER CHECK (commission_amount IS NULL OR commission_amount >= 0),
  commission_rate DECIMAL(5, 4),
  currency TEXT NOT NULL DEFAULT 'BDT',
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  settlement_id UUID, -- FK added after settlements table exists
  payout_id UUID,     -- FK added after payouts table exists
  reference TEXT,     -- external ref / receipt no.
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ledger_partner ON public.partner_ledger_entries(partner_id);
CREATE INDEX IF NOT EXISTS idx_ledger_partner_created ON public.partner_ledger_entries(partner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_order ON public.partner_ledger_entries(order_id);
CREATE INDEX IF NOT EXISTS idx_ledger_type ON public.partner_ledger_entries(entry_type);
CREATE INDEX IF NOT EXISTS idx_ledger_settlement ON public.partner_ledger_entries(settlement_id);

-- One sale_credit per partner per order (idempotent posting)
CREATE UNIQUE INDEX IF NOT EXISTS uq_ledger_sale_credit_order_partner
  ON public.partner_ledger_entries(order_id, partner_id)
  WHERE entry_type = 'sale_credit' AND order_id IS NOT NULL;

ALTER TABLE public.partner_ledger_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view ledger"
  ON public.partner_ledger_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
    OR EXISTS (
      SELECT 1 FROM public.partners p
      WHERE p.id = partner_ledger_entries.partner_id
        AND p.profile_id = auth.uid()
    )
  );

CREATE POLICY "Admins and operators can insert ledger"
  ON public.partner_ledger_entries FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
  );

-- No UPDATE/DELETE policies for staff by default — treat as append-only.
-- Corrections = new adjustment / clawback rows.

-- --------------------------------------------
-- 2. Settlements (period batches)
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS public.partner_settlements (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE RESTRICT,
  settlement_number TEXT UNIQUE NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
    'open',        -- accumulating
    'pending_review',
    'approved',    -- ready to pay
    'partially_paid',
    'paid',
    'void'
  )),
  -- Snapshot totals at close/approve time (BDT integers)
  gross_sales INTEGER NOT NULL DEFAULT 0 CHECK (gross_sales >= 0),
  total_commission INTEGER NOT NULL DEFAULT 0 CHECK (total_commission >= 0),
  net_payable INTEGER NOT NULL DEFAULT 0, -- what partner should receive for this batch
  amount_paid INTEGER NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
  currency TEXT NOT NULL DEFAULT 'BDT',
  notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES public.profiles(id),
  approved_by UUID REFERENCES public.profiles(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CHECK (period_end >= period_start)
);

CREATE INDEX IF NOT EXISTS idx_settlements_partner ON public.partner_settlements(partner_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON public.partner_settlements(status);
CREATE INDEX IF NOT EXISTS idx_settlements_period ON public.partner_settlements(period_start, period_end);

CREATE SEQUENCE IF NOT EXISTS public.settlement_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_settlement_number()
RETURNS TEXT AS $$
DECLARE
  n BIGINT;
BEGIN
  n := nextval('public.settlement_number_seq');
  RETURN 'SET-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(n::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

ALTER TABLE public.partner_settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view settlements"
  ON public.partner_settlements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
    OR EXISTS (
      SELECT 1 FROM public.partners p
      WHERE p.id = partner_settlements.partner_id
        AND p.profile_id = auth.uid()
    )
  );

CREATE POLICY "Staff can manage settlements"
  ON public.partner_settlements FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
  );

CREATE TRIGGER update_partner_settlements_updated_at
  BEFORE UPDATE ON public.partner_settlements
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- --------------------------------------------
-- 3. Settlement line items (which orders)
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS public.partner_settlement_lines (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  settlement_id UUID NOT NULL REFERENCES public.partner_settlements(id) ON DELETE CASCADE,
  ledger_entry_id UUID NOT NULL REFERENCES public.partner_ledger_entries(id) ON DELETE RESTRICT,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  gross_amount INTEGER NOT NULL DEFAULT 0,
  commission_amount INTEGER NOT NULL DEFAULT 0,
  net_amount INTEGER NOT NULL, -- should match ledger amount_signed for sale_credit
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (settlement_id, ledger_entry_id)
);

CREATE INDEX IF NOT EXISTS idx_settlement_lines_settlement ON public.partner_settlement_lines(settlement_id);
CREATE INDEX IF NOT EXISTS idx_settlement_lines_order ON public.partner_settlement_lines(order_id);

ALTER TABLE public.partner_settlement_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view settlement lines"
  ON public.partner_settlement_lines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
  );

CREATE POLICY "Staff can manage settlement lines"
  ON public.partner_settlement_lines FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
  );

-- --------------------------------------------
-- 4. Payouts (cash/bank/bKash out)
-- --------------------------------------------
CREATE TABLE IF NOT EXISTS public.partner_payouts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  partner_id UUID NOT NULL REFERENCES public.partners(id) ON DELETE RESTRICT,
  settlement_id UUID REFERENCES public.partner_settlements(id) ON DELETE SET NULL,
  payout_number TEXT UNIQUE NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'BDT',
  method TEXT NOT NULL DEFAULT 'cash' CHECK (method IN (
    'cash', 'bank_transfer', 'bkash', 'nagad', 'rocket', 'other'
  )),
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN (
    'pending', 'completed', 'failed', 'cancelled'
  )),
  paid_at TIMESTAMPTZ DEFAULT NOW(),
  external_reference TEXT, -- bKash trx id, bank ref
  notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS public.payout_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_payout_number()
RETURNS TEXT AS $$
DECLARE
  n BIGINT;
BEGIN
  n := nextval('public.payout_number_seq');
  RETURN 'PAY-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(n::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_payouts_partner ON public.partner_payouts(partner_id);
CREATE INDEX IF NOT EXISTS idx_payouts_settlement ON public.partner_payouts(settlement_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.partner_payouts(status);

ALTER TABLE public.partner_payouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can view payouts"
  ON public.partner_payouts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
    OR EXISTS (
      SELECT 1 FROM public.partners p
      WHERE p.id = partner_payouts.partner_id
        AND p.profile_id = auth.uid()
    )
  );

CREATE POLICY "Staff can manage payouts"
  ON public.partner_payouts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'operator')
    )
  );

-- FKs from ledger → settlement / payout
ALTER TABLE public.partner_ledger_entries
  DROP CONSTRAINT IF EXISTS partner_ledger_entries_settlement_id_fkey;
ALTER TABLE public.partner_ledger_entries
  ADD CONSTRAINT partner_ledger_entries_settlement_id_fkey
  FOREIGN KEY (settlement_id) REFERENCES public.partner_settlements(id) ON DELETE SET NULL;

ALTER TABLE public.partner_ledger_entries
  DROP CONSTRAINT IF EXISTS partner_ledger_entries_payout_id_fkey;
ALTER TABLE public.partner_ledger_entries
  ADD CONSTRAINT partner_ledger_entries_payout_id_fkey
  FOREIGN KEY (payout_id) REFERENCES public.partner_payouts(id) ON DELETE SET NULL;

-- --------------------------------------------
-- 5. Optional: link order_items → partner
-- --------------------------------------------
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS partner_id UUID REFERENCES public.partners(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_order_items_partner ON public.order_items(partner_id);

-- --------------------------------------------
-- 6. Views
-- --------------------------------------------
CREATE OR REPLACE VIEW public.partner_balances AS
SELECT
  p.id AS partner_id,
  p.shop_name,
  p.phone,
  p.is_active,
  COALESCE(SUM(le.amount_signed), 0)::INTEGER AS balance_owed_bdt,
  COALESCE(SUM(le.amount_signed) FILTER (WHERE le.entry_type = 'sale_credit'), 0)::INTEGER AS lifetime_credits_bdt,
  COALESCE(SUM(-le.amount_signed) FILTER (WHERE le.entry_type = 'payout' AND le.amount_signed < 0), 0)::INTEGER AS lifetime_payouts_bdt,
  COUNT(le.id) FILTER (WHERE le.entry_type = 'sale_credit') AS sale_credit_count,
  MAX(le.created_at) AS last_ledger_at
FROM public.partners p
LEFT JOIN public.partner_ledger_entries le ON le.partner_id = p.id
GROUP BY p.id, p.shop_name, p.phone, p.is_active;

CREATE OR REPLACE VIEW public.partner_unsettled_credits AS
SELECT
  le.*
FROM public.partner_ledger_entries le
WHERE le.entry_type = 'sale_credit'
  AND le.settlement_id IS NULL
  AND le.amount_signed > 0;

-- --------------------------------------------
-- 7. Functions — post sale credit (idempotent)
-- --------------------------------------------
-- Posts net credit for one partner for one delivered order.
-- Net = gross_merchandise - commission.
-- Prefer summing order_items for that partner_id; fallback: full order subtotal
-- when partner_id is passed explicitly and items have no partner_id.

CREATE OR REPLACE FUNCTION public.post_partner_sale_credit(
  p_order_id UUID,
  p_partner_id UUID,
  p_gross_override INTEGER DEFAULT NULL,
  p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_partner public.partners%ROWTYPE;
  v_gross INTEGER;
  v_rate DECIMAL(5, 4);
  v_commission INTEGER;
  v_net INTEGER;
  v_entry_id UUID;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'order not found: %', p_order_id;
  END IF;

  IF v_order.status NOT IN ('delivered', 'out_for_delivery', 'processing', 'confirmed') THEN
    -- Allow posting from confirmed onward; ops may tighten to delivered only
    NULL;
  END IF;

  SELECT * INTO v_partner FROM public.partners WHERE id = p_partner_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'partner not found: %', p_partner_id;
  END IF;

  -- Idempotent: existing sale_credit
  SELECT id INTO v_entry_id
  FROM public.partner_ledger_entries
  WHERE order_id = p_order_id
    AND partner_id = p_partner_id
    AND entry_type = 'sale_credit'
  LIMIT 1;

  IF v_entry_id IS NOT NULL THEN
    RETURN v_entry_id;
  END IF;

  IF p_gross_override IS NOT NULL THEN
    v_gross := p_gross_override;
  ELSE
    SELECT COALESCE(SUM(oi.total), 0)::INTEGER INTO v_gross
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id
      AND oi.partner_id = p_partner_id;

    IF v_gross = 0 THEN
      -- Fallback: whole order merchandise (subtotal), not delivery fee
      v_gross := COALESCE(v_order.subtotal, 0);
    END IF;
  END IF;

  IF v_gross <= 0 THEN
    RAISE EXCEPTION 'gross amount must be positive for order % partner %', p_order_id, p_partner_id;
  END IF;

  v_rate := COALESCE(v_partner.commission_rate, 0.10);
  v_commission := FLOOR(v_gross * v_rate)::INTEGER;
  v_net := v_gross - v_commission;

  IF v_net <= 0 THEN
    RAISE EXCEPTION 'net payable must be positive (gross=%, rate=%)', v_gross, v_rate;
  END IF;

  INSERT INTO public.partner_ledger_entries (
    partner_id,
    entry_type,
    amount_signed,
    gross_amount,
    commission_amount,
    commission_rate,
    order_id,
    description,
    created_by
  ) VALUES (
    p_partner_id,
    'sale_credit',
    v_net,
    v_gross,
    v_commission,
    v_rate,
    p_order_id,
    'Sale credit for order ' || COALESCE(v_order.order_number, p_order_id::TEXT),
    p_created_by
  )
  RETURNING id INTO v_entry_id;

  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------
-- 8. Close settlement for partner + period
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.close_partner_settlement(
  p_partner_id UUID,
  p_period_start DATE,
  p_period_end DATE,
  p_created_by UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_settlement_id UUID;
  v_gross INTEGER := 0;
  v_commission INTEGER := 0;
  v_net INTEGER := 0;
  r RECORD;
BEGIN
  IF p_period_end < p_period_start THEN
    RAISE EXCEPTION 'period_end must be >= period_start';
  END IF;

  INSERT INTO public.partner_settlements (
    partner_id,
    settlement_number,
    period_start,
    period_end,
    status,
    notes,
    created_by
  ) VALUES (
    p_partner_id,
    public.generate_settlement_number(),
    p_period_start,
    p_period_end,
    'pending_review',
    p_notes,
    p_created_by
  )
  RETURNING id INTO v_settlement_id;

  FOR r IN
    SELECT le.*
    FROM public.partner_ledger_entries le
    WHERE le.partner_id = p_partner_id
      AND le.entry_type = 'sale_credit'
      AND le.settlement_id IS NULL
      AND le.amount_signed > 0
      AND le.created_at::DATE >= p_period_start
      AND le.created_at::DATE <= p_period_end
  LOOP
    INSERT INTO public.partner_settlement_lines (
      settlement_id,
      ledger_entry_id,
      order_id,
      gross_amount,
      commission_amount,
      net_amount
    ) VALUES (
      v_settlement_id,
      r.id,
      r.order_id,
      COALESCE(r.gross_amount, 0),
      COALESCE(r.commission_amount, 0),
      r.amount_signed
    );

    UPDATE public.partner_ledger_entries
    SET settlement_id = v_settlement_id
    WHERE id = r.id;

    v_gross := v_gross + COALESCE(r.gross_amount, 0);
    v_commission := v_commission + COALESCE(r.commission_amount, 0);
    v_net := v_net + r.amount_signed;
  END LOOP;

  UPDATE public.partner_settlements
  SET
    gross_sales = v_gross,
    total_commission = v_commission,
    net_payable = v_net,
    updated_at = NOW()
  WHERE id = v_settlement_id;

  RETURN v_settlement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------
-- 9. Record payout + ledger debit
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.record_partner_payout(
  p_partner_id UUID,
  p_amount INTEGER,
  p_method TEXT DEFAULT 'cash',
  p_settlement_id UUID DEFAULT NULL,
  p_external_reference TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_payout_id UUID;
  v_settlement public.partner_settlements%ROWTYPE;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'payout amount must be positive';
  END IF;

  INSERT INTO public.partner_payouts (
    partner_id,
    settlement_id,
    payout_number,
    amount,
    method,
    status,
    external_reference,
    notes,
    created_by
  ) VALUES (
    p_partner_id,
    p_settlement_id,
    public.generate_payout_number(),
    p_amount,
    COALESCE(p_method, 'cash'),
    'completed',
    p_external_reference,
    p_notes,
    p_created_by
  )
  RETURNING id INTO v_payout_id;

  INSERT INTO public.partner_ledger_entries (
    partner_id,
    entry_type,
    amount_signed,
    payout_id,
    settlement_id,
    reference,
    description,
    created_by
  ) VALUES (
    p_partner_id,
    'payout',
    -p_amount,
    v_payout_id,
    p_settlement_id,
    p_external_reference,
    'Payout ' || p_amount::TEXT || ' BDT via ' || COALESCE(p_method, 'cash'),
    p_created_by
  );

  IF p_settlement_id IS NOT NULL THEN
    SELECT * INTO v_settlement FROM public.partner_settlements WHERE id = p_settlement_id;
    IF FOUND THEN
      UPDATE public.partner_settlements
      SET
        amount_paid = amount_paid + p_amount,
        status = CASE
          WHEN amount_paid + p_amount >= net_payable THEN 'paid'
          WHEN amount_paid + p_amount > 0 THEN 'partially_paid'
          ELSE status
        END,
        updated_at = NOW()
      WHERE id = p_settlement_id;
    END IF;
  END IF;

  RETURN v_payout_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------
-- 10. Stock decrement helper (optional call)
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.decrement_stock_for_order(p_order_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.products pr
  SET
    stock_quantity = GREATEST(0, pr.stock_quantity - oi.quantity),
    in_stock = CASE
      WHEN GREATEST(0, pr.stock_quantity - oi.quantity) <= 0 THEN false
      ELSE pr.in_stock
    END,
    updated_at = NOW()
  FROM public.order_items oi
  WHERE oi.order_id = p_order_id
    AND oi.product_id = pr.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------
-- 11. Settings defaults for settlements
-- --------------------------------------------
INSERT INTO public.settings (key, value, description) VALUES
  ('settlement_cycle_days', '7', 'Default settlement period length in days'),
  ('default_commission_rate', '0.11', 'Fallback commission if partner rate null'),
  ('settlement_auto_post_on_delivered', 'true', 'If true, ops should call post_partner_sale_credit when order delivered')
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- USAGE CHEATSHEET (SQL Editor)
-- ============================================
-- 1) After order delivered, post credit:
--    SELECT public.post_partner_sale_credit('<order_uuid>', '<partner_uuid>');
--
-- 2) Weekly close:
--    SELECT public.close_partner_settlement(
--      '<partner_uuid>',
--      CURRENT_DATE - 7,
--      CURRENT_DATE,
--      auth.uid(),
--      'Week close'
--    );
--
-- 3) Pay partner:
--    SELECT public.record_partner_payout(
--      '<partner_uuid>',
--      5000,
--      'bkash',
--      '<settlement_uuid>',
--      'TRX123',
--      'Weekly payout'
--    );
--
-- 4) Balances:
--    SELECT * FROM public.partner_balances;
-- ============================================
