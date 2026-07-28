-- ============================================
-- JG Mart — Sample partners (Japan Garden City)
-- Run AFTER schema.sql (+ migration 002 optional)
-- Synthetic pilot data — replace phones before production
-- ============================================

INSERT INTO public.partners (
  id, shop_name, category, contact_name, phone, whatsapp, address,
  commission_rate, is_active, is_verified, cutoff_time, pickup_start, pickup_end
) VALUES
  (
    'a1000001-0001-4000-8000-000000000001',
    'JGC Krishi Corner',
    'vegetables',
    'Karim Mia',
    '01711110001',
    '8801711110001',
    'Near Gate 2, Japan Garden City',
    0.12, true, true,
    '09:00', '10:00', '11:00'
  ),
  (
    'a1000001-0001-4000-8000-000000000002',
    'City Grocery Traders',
    'rice_dal',
    'Abdul Malek',
    '01711110002',
    '8801711110002',
    'Ring Road side, Mohammadpur',
    0.09, true, true,
    '09:00', '10:00', '11:00'
  ),
  (
    'a1000001-0001-4000-8000-000000000003',
    'Fresh Catch BD',
    'fish',
    'Shafiqul Islam',
    '01711110003',
    '8801711110003',
    'Fish market supply — JGC pickup',
    0.08, true, true,
    '08:30', '09:30', '10:30'
  ),
  (
    'a1000001-0001-4000-8000-000000000004',
    'Halal Meats JGC',
    'meat',
    'Rafiq Hossain',
    '01711110004',
    '8801711110004',
    'Cluster 3 service road',
    0.08, true, true,
    '09:00', '10:00', '11:00'
  ),
  (
    'a1000001-0001-4000-8000-000000000005',
    'Green Dairy',
    'dairy_eggs',
    'Nasrin Sultana',
    '01711110005',
    '8801711110005',
    'Morning milk route — JGC',
    0.10, true, true,
    '08:00', '09:00', '10:00'
  ),
  (
    'a1000001-0001-4000-8000-000000000006',
    'Daily Needs BD',
    'fmcg',
    'Imran Chowdhury',
    '01711110006',
    '8801711110006',
    'Wholesale lane, Mohammadpur',
    0.07, true, false,
    '09:00', '10:30', '11:30'
  )
ON CONFLICT (id) DO UPDATE SET
  shop_name = EXCLUDED.shop_name,
  commission_rate = EXCLUDED.commission_rate,
  is_active = EXCLUDED.is_active;
