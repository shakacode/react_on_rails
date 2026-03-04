import React from 'react';
import ReviewItem from '../client/ReviewItem';
import type { Review } from '../data';

export default function ReviewsList({ reviews }: { reviews: Review[] }) {
  const avgRating = reviews.reduce((sum, r) => sum + r.stars, 0) / reviews.length;

  return (
    <section className="reviews-section">
      <h2 className="section-title">Customer Reviews</h2>
      <div className="reviews-summary">
        <span className="reviews-average">{avgRating.toFixed(1)} out of 5</span>
        <span className="reviews-count">Based on {reviews.length} reviews</span>
      </div>
      <div className="reviews-list">
        {reviews.map((review) => (
          <ReviewItem key={review.id} review={review} />
        ))}
      </div>
    </section>
  );
}
