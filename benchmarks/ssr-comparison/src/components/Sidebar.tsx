import React from 'react';
import FilterCheckbox from '../client/FilterCheckbox';

const categories = ['Monitors', 'Keyboards', 'Mice', 'Audio', 'Storage', 'Cables', 'Furniture', 'Lighting'];
const priceRanges = ['Under $25', '$25 - $50', '$50 - $100', '$100 - $200', 'Over $200'];
const brands = ['TechPro', 'WorkStation', 'DesignLab', 'ErgoCo', 'AudioMax'];

export default function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-section">
        <h3 className="sidebar-heading">Categories</h3>
        <div className="filter-list">
          {categories.map((cat) => (
            <FilterCheckbox key={cat} label={cat} />
          ))}
        </div>
      </div>
      <div className="sidebar-section">
        <h3 className="sidebar-heading">Price Range</h3>
        <div className="filter-list">
          {priceRanges.map((range) => (
            <FilterCheckbox key={range} label={range} />
          ))}
        </div>
      </div>
      <div className="sidebar-section">
        <h3 className="sidebar-heading">Brand</h3>
        <div className="filter-list">
          {brands.map((brand) => (
            <FilterCheckbox key={brand} label={brand} />
          ))}
        </div>
      </div>
      <div className="sidebar-section">
        <h3 className="sidebar-heading">Rating</h3>
        <div className="filter-list">
          {[4, 3, 2, 1].map((stars) => (
            <FilterCheckbox key={stars} label={`${stars}+ Stars`} />
          ))}
        </div>
      </div>
    </aside>
  );
}
