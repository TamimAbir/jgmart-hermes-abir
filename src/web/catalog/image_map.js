/**
 * JG Mart — local product image map (category tiles)
 * Include before product render, or import from modules.
 */
window.JG_CAT_IMAGES = {
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

window.jgLocalImage = function (category) {
  const m = window.JG_CAT_IMAGES || {};
  return m[category] || 'images/cat_vegetables.svg';
};

/** Remap product list in-place (mutates). */
window.jgRemapProductImages = function (products) {
  if (!Array.isArray(products)) return products;
  products.forEach(function (p) {
    const cat = p.ct || p.category || p.category_id || '';
    p.im = window.jgLocalImage(cat);
    p.image = p.im;
  });
  return products;
};
