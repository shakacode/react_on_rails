import React from 'react';

interface BreadcrumbItem {
  label: string;
  href: string;
}

export default function Breadcrumb({ items }: { items: BreadcrumbItem[] }) {
  return (
    <nav className="breadcrumb" aria-label="Breadcrumb">
      <ol className="breadcrumb-list">
        {items.map((item, i) => (
          <li key={item.href} className="breadcrumb-item">
            {i < items.length - 1 ? (
              <>
                <a href={item.href} className="breadcrumb-link">{item.label}</a>
                <span className="breadcrumb-separator" aria-hidden="true"> / </span>
              </>
            ) : (
              <span className="breadcrumb-current" aria-current="page">{item.label}</span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}
