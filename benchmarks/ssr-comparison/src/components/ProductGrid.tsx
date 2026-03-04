import React from 'react';
import ProductCard from '../client/ProductCard';
import type { Product } from '../data';

export default function ProductGrid({ products }: { products: Product[] }) {
  return (
    <section className="product-grid-section">
      <h2 className="section-title">Featured Products</h2>
      <p className="section-subtitle">Showing {products.length} products</p>
      <div className="product-grid">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}
