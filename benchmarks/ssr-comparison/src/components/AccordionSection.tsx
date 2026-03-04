import React from 'react';
import AccordionItem from '../client/AccordionItem';
import type { FAQItem } from '../data';

export default function AccordionSection({ items }: { items: FAQItem[] }) {
  return (
    <section className="accordion-section">
      <h2 className="section-title">Frequently Asked Questions</h2>
      <div className="accordion">
        {items.map((item, i) => (
          <AccordionItem key={i} question={item.question} answer={item.answer} />
        ))}
      </div>
    </section>
  );
}
