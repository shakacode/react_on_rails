'use client';

import React, { useState } from 'react';
import type { Product } from '../data';

/**
 * Simplified ProductCard: 7 elements instead of ~28.
 * - Stars: single span with concatenated characters (was 5 individual spans + wrapper)
 * - Specs: single text line (was table with 5 rows × 2 cells)
 * - No hover handlers on stars (irrelevant for SSR)
 */
export default function ProductCardLite({ product }: { product: Product }) {
  const [inCart, setInCart] = useState(false);
  const stars = '\u2605'.repeat(product.rating) + '\u2606'.repeat(5 - product.rating);
  const specs = Object.entries(product.specs).map(([k, v]) => `${k}: ${v}`).join(' \u00b7 ');

  return (
    <div className="product-card" data-product-id={product.id}>
      <img src={product.image} alt={product.name} width={200} height={200} />
      <h3 className="product-name">{product.name}</h3>
      <p className="product-price">${product.price.toFixed(2)}</p>
      <span className="product-rating">{stars} ({product.rating}/5)</span>
      <p className="product-description">{product.description}</p>
      <p className="product-specs">{specs}</p>
      <button
        className={`add-to-cart ${inCart ? 'in-cart' : ''}`}
        onClick={() => setInCart(!inCart)}
      >
        {inCart ? 'Remove from Cart' : 'Add to Cart'}
      </button>
    </div>
  );
}
