/**
 * JG Mart — Catalog Database Integration
 *
 * Supabase when configured; falls back to catalog_data.json.
 * Product images are remapped to local category SVGs so the site
 * works offline and without external CDN dependency.
 */

import { supabase } from '../supabase/client.js';

// Prefer JSON/local until Supabase keys are real (config.js placeholders).
const USE_SUPABASE = false;

const LOCAL_CATEGORY_IMAGES = {
  rice_dal: 'images/cat_rice_dal.svg',
  oil_spices: 'images/cat_oil_spices.svg',
  vegetables: 'images/cat_vegetables.svg',
  fish: 'images/cat_fish.svg',
  meat: 'images/cat_meat.svg',
  dairy_eggs: 'images/cat_dairy_eggs.svg',
  fruits: 'images/cat_fruits.svg',
  fmcg: 'images/cat_fmcg.svg',
  beverages: 'images/cat_beverages.svg',
  snacks: 'images/cat_snacks.svg'
};

function withLocalImages(products) {
  if (!Array.isArray(products)) return [];
  return products.map((p) => {
    const cat = p.category || p.category_id || '';
    const local = LOCAL_CATEGORY_IMAGES[cat] || 'images/cat_vegetables.svg';
    return {
      ...p,
      image: local,
      image_url: local,
      thumbnail_url: local
    };
  });
}

// ============================================
// PRODUCTS
// ============================================
async function loadProductsFromDB() {
  if (!USE_SUPABASE) {
    return loadProductsFromJSON();
  }

  try {
    const { data, error } = await supabase
      .from('products')
      .select('*, categories(*)')
      .eq('in_stock', true)
      .order('sort_order', { ascending: true });

    if (error) throw error;

    const mapped = (data || []).map((row) => ({
      id: row.id,
      name: row.name,
      name_bn: row.name_bn,
      category: row.category_id,
      price: row.price,
      unit: row.unit,
      desc: row.description,
      desc_bn: row.description_bn,
      image: row.image_url,
      stock_status: row.in_stock ? 'in_stock' : 'out_of_stock'
    }));

    return withLocalImages(mapped);
  } catch (error) {
    console.warn('Failed to load from Supabase, falling back to JSON:', error);
    return loadProductsFromJSON();
  }
}

function loadProductsFromJSON() {
  return fetch('catalog_data.json')
    .then((r) => r.json())
    .then((data) => withLocalImages(data.products || []))
    .catch((err) => {
      console.error('Failed to load catalog_data.json:', err);
      return [];
    });
}

// ============================================
// CATEGORIES
// ============================================
async function loadCategoriesFromDB() {
  if (!USE_SUPABASE) {
    return loadCategoriesFromJSON();
  }

  try {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });

    if (error) throw error;

    return data || [];
  } catch (error) {
    console.warn('Failed to load categories from Supabase, falling back to JSON:', error);
    return loadCategoriesFromJSON();
  }
}

function loadCategoriesFromJSON() {
  return fetch('catalog_data.json')
    .then((r) => r.json())
    .then((data) => data.categories || [])
    .catch((err) => {
      console.error('Failed to load categories:', err);
      return [];
    });
}

// ============================================
// ORDERS
// ============================================
async function submitOrder(orderData) {
  if (!USE_SUPABASE) {
    return saveOrderToLocalStorage(orderData);
  }

  try {
    const { data: orderNum, error: numError } = await supabase.rpc('generate_order_number');
    if (numError) throw numError;

    const { data, error } = await supabase
      .from('orders')
      .insert([
        {
          order_number: orderNum || `JG-${Date.now()}`,
          customer_name: orderData.customerName,
          customer_phone: orderData.customerPhone,
          customer_building: orderData.building,
          customer_flat: orderData.flat,
          delivery_zone_id: orderData.zoneId || 1,
          delivery_slot: orderData.slot || 'morning',
          delivery_date: orderData.deliveryDate || new Date().toISOString().split('T')[0],
          items: orderData.items,
          subtotal: orderData.subtotal,
          delivery_fee: orderData.deliveryFee,
          total: orderData.total,
          payment_method: orderData.paymentMethod || 'cash',
          status: 'pending'
        }
      ])
      .select()
      .single();

    if (error) throw error;

    if (orderData.items && orderData.items.length > 0) {
      const items = orderData.items.map((item) => ({
        order_id: data.id,
        product_id: item.id,
        product_name: item.name,
        quantity: item.qty,
        unit_price: item.price,
        total: item.price * item.qty,
        partner_id: item.partner_id || null
      }));

      const { error: itemsError } = await supabase.from('order_items').insert(items);
      if (itemsError) console.error('Failed to insert order items:', itemsError);
    }

    return { success: true, order: data };
  } catch (error) {
    console.error('Failed to submit order to Supabase:', error);
    return saveOrderToLocalStorage(orderData);
  }
}

function saveOrderToLocalStorage(orderData) {
  const orders = JSON.parse(localStorage.getItem('jgmart_ords') || '[]');
  const newOrder = {
    id: 'ORD-' + Date.now(),
    ...orderData,
    date: new Date().toISOString(),
    status: 'pending'
  };
  orders.push(newOrder);
  localStorage.setItem('jgmart_ords', JSON.stringify(orders));
  return { success: true, order: newOrder };
}

// ============================================
// SETTINGS
// ============================================
async function loadSettings() {
  if (!USE_SUPABASE) {
    return loadSettingsFromLocalStorage();
  }

  try {
    const { data, error } = await supabase.from('settings').select('*');
    if (error) throw error;

    const settings = {};
    data?.forEach((s) => {
      settings[s.key] = s.value;
    });
    return settings;
  } catch (error) {
    console.warn('Failed to load settings from Supabase, using defaults:', error);
    return loadSettingsFromLocalStorage();
  }
}

function loadSettingsFromLocalStorage() {
  return {
    whatsapp_number: localStorage.getItem('jgmart_wa') || '8801870489448',
    delivery_fee_bdt: 30,
    aov_bdt: 800,
    site_name: 'JG Mart',
    location: 'Japan Garden City, Dhaka'
  };
}

export {
  loadProductsFromDB,
  loadCategoriesFromDB,
  submitOrder,
  loadSettings,
  withLocalImages,
  LOCAL_CATEGORY_IMAGES
};
