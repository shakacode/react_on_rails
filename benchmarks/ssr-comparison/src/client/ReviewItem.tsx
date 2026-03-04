'use client';

import React, { useState } from 'react';
import type { Review } from '../data';

export default function ReviewItem({ review }: { review: Review }) {
  const [helpful, setHelpful] = useState<'yes' | 'no' | null>(null);

  return (
    <article className="review-item" data-review-id={review.id}>
      <header className="review-header">
        <div className="review-stars">
          {Array.from({ length: 5 }, (_, i) => (
            <span key={i} className={i < review.stars ? 'star filled' : 'star empty'}>
              {i < review.stars ? '\u2605' : '\u2606'}
            </span>
          ))}
        </div>
        <h4 className="review-title">{review.title}</h4>
        <div className="review-meta">
          <span className="review-author">By {review.author}</span>
          <span className="review-date"> on {review.date}</span>
        </div>
      </header>
      <div className="review-body">
        {review.body.split('\n\n').map((paragraph, i) => (
          <p key={i}>{paragraph}</p>
        ))}
      </div>
      <footer className="review-footer">
        <span className="review-helpful-label">Was this review helpful?</span>
        <button
          className={`btn-helpful ${helpful === 'yes' ? 'selected' : ''}`}
          onClick={() => setHelpful(helpful === 'yes' ? null : 'yes')}
        >
          Yes
        </button>
        <button
          className={`btn-not-helpful ${helpful === 'no' ? 'selected' : ''}`}
          onClick={() => setHelpful(helpful === 'no' ? null : 'no')}
        >
          No
        </button>
      </footer>
    </article>
  );
}
