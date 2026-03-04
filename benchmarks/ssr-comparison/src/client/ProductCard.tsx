'use client';

import React, { useState } from 'react';
import type { Product } from '../data';

export default function ProductCard({ product }: { product: Product }) {
  const [hoveredStar, setHoveredStar] = useState(0);
  const [inCart, setInCart] = useState(false);

  return (
    <div className="product-card" data-product-id={product.id}>
      <div className="product-image">
        <img src={product.image} alt={product.name} width={200} height={200} />
      </div>
      <h3 className="product-name">{product.name}</h3>
      <p className="product-price">${product.price.toFixed(2)}</p>
      <div className="product-rating">
        {[1, 2, 3, 4, 5].map((star) => (
          <span
            key={star}
            className={`star ${star <= (hoveredStar || product.rating) ? 'filled' : 'empty'}`}
            onMouseEnter={() => setHoveredStar(star)}
            onMouseLeave={() => setHoveredStar(0)}
          >
            {star <= (hoveredStar || product.rating) ? '\u2605' : '\u2606'}
          </span>
        ))}
        <span className="rating-count">({product.rating}/5)</span>
      </div>
      <p className="product-description">{product.description}</p>
      <table className="product-specs">
        <tbody>
          {Object.entries(product.specs).map(([key, value]) => (
            <tr key={key}>
              <td className="spec-key">{key}</td>
              <td className="spec-value">{value}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <button
        className={`add-to-cart ${inCart ? 'in-cart' : ''}`}
        onClick={() => setInCart(!inCart)}
      >
        {inCart ? 'Remove from Cart' : 'Add to Cart'}
      </button>
    </div>
  );
}
