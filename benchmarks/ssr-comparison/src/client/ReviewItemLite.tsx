'use client';

import React, { useState } from 'react';
import type { Review } from '../data';

/**
 * Simplified ReviewItem: ~7 elements instead of ~17.
 * - Stars: single span (was 5 individual spans + wrapper div)
 * - Body: single paragraph (was split by \n\n into multiple p tags)
 * - Flattened header structure
 */
export default function ReviewItemLite({ review }: { review: Review }) {
  const [helpful, setHelpful] = useState<'yes' | 'no' | null>(null);
  const stars = '\u2605'.repeat(review.stars) + '\u2606'.repeat(5 - review.stars);

  return (
    <article className="review-item" data-review-id={review.id}>
      <span className="review-stars">{stars}</span>
      <h4 className="review-title">{review.title}</h4>
      <span className="review-meta">By {review.author} on {review.date}</span>
      <p className="review-body">{review.body}</p>
      <footer className="review-footer">
        <span className="review-helpful-label">Was this review helpful?</span>
        <button
          className={`btn-helpful ${helpful === 'yes' ? 'selected' : ''}`}
          onClick={() => setHelpful(helpful === 'yes' ? null : 'yes')}
        >Yes</button>
        <button
          className={`btn-not-helpful ${helpful === 'no' ? 'selected' : ''}`}
          onClick={() => setHelpful(helpful === 'no' ? null : 'no')}
        >No</button>
      </footer>
    </article>
  );
}
