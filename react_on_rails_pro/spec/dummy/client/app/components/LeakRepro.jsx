'use client';

import React from 'react';

function LeakRepro({ items }) {
  return (
    <section className="leak-repro">
      <h1 style={{ fontSize: '24px', marginBottom: '16px', color: '#111' }}>
        Memory Leak Reproducer — {items.length} Items
      </h1>
      {items.map((item) => (
        <div
          key={item.id}
          data-idx={item.id}
          style={{
            padding: '12px 16px',
            margin: '8px 0',
            border: `1px solid ${item.color}`,
            backgroundColor: item.bgColor,
          }}
        >
          <h3 style={{ color: '#333', fontSize: '14px', fontWeight: 600 }}>{item.title}</h3>
          <ul style={{ listStyle: 'none', padding: 0, display: 'flex', gap: '8px' }}>
            {item.tags.map((tag) => (
              <li
                key={tag}
                style={{
                  padding: '2px 8px',
                  borderRadius: '4px',
                  backgroundColor: '#e0e0e0',
                  color: '#444',
                  fontSize: '12px',
                }}
              >
                {tag}
              </li>
            ))}
          </ul>
          <p style={{ lineHeight: '1.6', color: '#555', margin: '8px 0' }}>{item.body}</p>
          <span style={{ fontSize: '11px', color: '#888' }}>
            by <em>{item.author}</em> on <time>{item.date}</time> — {item.score} points
          </span>
        </div>
      ))}
    </section>
  );
}

export default LeakRepro;
