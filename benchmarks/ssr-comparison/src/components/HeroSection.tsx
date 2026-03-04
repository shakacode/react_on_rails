import React from 'react';

export default function HeroSection() {
  return (
    <section className="hero-section">
      <div className="hero-background">
        <div className="hero-overlay" />
      </div>
      <div className="hero-content">
        <h1 className="hero-title">Premium Tech for Modern Workspaces</h1>
        <p className="hero-subtitle">
          Discover our curated collection of professional-grade peripherals, monitors,
          and workspace accessories. Engineered for productivity, designed for comfort.
        </p>
        <div className="hero-cta">
          <a href="/products" className="btn-primary">Shop Now</a>
          <a href="/solutions" className="btn-secondary">Explore Solutions</a>
        </div>
        <div className="hero-stats">
          <div className="stat-item">
            <span className="stat-number">50,000+</span>
            <span className="stat-label">Happy Customers</span>
          </div>
          <div className="stat-item">
            <span className="stat-number">4.8/5</span>
            <span className="stat-label">Average Rating</span>
          </div>
          <div className="stat-item">
            <span className="stat-number">500+</span>
            <span className="stat-label">Products</span>
          </div>
          <div className="stat-item">
            <span className="stat-number">24/7</span>
            <span className="stat-label">Support</span>
          </div>
        </div>
      </div>
    </section>
  );
}
