import React from 'react';
import SearchInput from '../client/SearchInput';
import type { NavItem } from '../data';

function NavLink({ item }: { item: NavItem }) {
  return (
    <li className="nav-item">
      <a href={item.href} className="nav-link">{item.label}</a>
      {item.children && item.children.length > 0 && (
        <ul className="nav-dropdown">
          {item.children.map((child) => (
            <NavLink key={child.href} item={child} />
          ))}
        </ul>
      )}
    </li>
  );
}

export default function NavigationBar({ items }: { items: NavItem[] }) {
  return (
    <nav className="navigation-bar" role="navigation">
      <div className="nav-brand">
        <a href="/" className="brand-logo">TechStore</a>
      </div>
      <ul className="nav-menu">
        {items.map((item) => (
          <NavLink key={item.href} item={item} />
        ))}
      </ul>
      <div className="nav-search">
        <SearchInput placeholder="Search products..." />
      </div>
      <div className="nav-actions">
        <a href="/cart" className="nav-cart">Cart (0)</a>
        <a href="/account" className="nav-account">Account</a>
      </div>
    </nav>
  );
}
