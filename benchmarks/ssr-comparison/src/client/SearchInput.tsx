'use client';

import React, { useState } from 'react';

export default function SearchInput({ placeholder = 'Search...' }: { placeholder?: string }) {
  const [query, setQuery] = useState('');

  return (
    <div className="search-input-wrapper">
      <input
        type="text"
        className="search-input"
        placeholder={placeholder}
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        aria-label="Search"
      />
      {query && (
        <button className="search-clear" onClick={() => setQuery('')} aria-label="Clear search">
          &times;
        </button>
      )}
    </div>
  );
}
