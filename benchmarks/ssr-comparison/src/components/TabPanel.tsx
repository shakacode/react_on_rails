import React from 'react';

interface Tab {
  id: string;
  label: string;
  content: string;
}

export default function TabPanel({ tabs }: { tabs: Tab[] }) {
  return (
    <section className="tab-panel-section">
      <h2 className="section-title">Product Details</h2>
      <div className="tab-panel" role="tablist">
        <div className="tab-headers">
          {tabs.map((tab, i) => (
            <button
              key={tab.id}
              className={`tab-header ${i === 0 ? 'active' : ''}`}
              role="tab"
              aria-selected={i === 0}
              aria-controls={`panel-${tab.id}`}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <div className="tab-contents">
          {tabs.map((tab, i) => (
            <div
              key={tab.id}
              id={`panel-${tab.id}`}
              className={`tab-content ${i === 0 ? 'visible' : 'hidden'}`}
              role="tabpanel"
            >
              <p>{tab.content}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
