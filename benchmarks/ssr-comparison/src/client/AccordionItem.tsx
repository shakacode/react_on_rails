'use client';

import React, { useState } from 'react';

export default function AccordionItem({ question, answer }: { question: string; answer: string }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className={`accordion-item ${expanded ? 'expanded' : 'collapsed'}`}>
      <button className="accordion-trigger" onClick={() => setExpanded(!expanded)}>
        <span className="accordion-question">{question}</span>
        <span className="accordion-icon">{expanded ? '\u25B2' : '\u25BC'}</span>
      </button>
      {expanded && (
        <div className="accordion-content">
          <p>{answer}</p>
        </div>
      )}
    </div>
  );
}
