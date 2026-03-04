import React from 'react';

export default function PaginationBar({ currentPage = 1, totalPages = 10 }: { currentPage?: number; totalPages?: number }) {
  const pages = Array.from({ length: totalPages }, (_, i) => i + 1);

  return (
    <nav className="pagination-bar" aria-label="Pagination">
      <button className="page-btn prev" disabled={currentPage === 1}>
        &laquo; Previous
      </button>
      <div className="page-numbers">
        {pages.map((page) => (
          <button
            key={page}
            className={`page-btn ${page === currentPage ? 'active' : ''}`}
            aria-current={page === currentPage ? 'page' : undefined}
          >
            {page}
          </button>
        ))}
      </div>
      <button className="page-btn next" disabled={currentPage === totalPages}>
        Next &raquo;
      </button>
      <span className="page-info">Page {currentPage} of {totalPages}</span>
    </nav>
  );
}
