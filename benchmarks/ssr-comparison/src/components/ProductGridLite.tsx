import React from 'react';
import ProductCardLite from '../client/ProductCardLite';
import type { Product } from '../data';

export default function ProductGridLite({ products }: { products: Product[] }) {
  return (
    <section className="product-grid-section">
      <h2 className="section-title">Featured Products</h2>
      <p className="section-subtitle">Showing {products.length} products</p>
      <div className="product-grid">
        {products.map((product) => (
          <ProductCardLite key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}
