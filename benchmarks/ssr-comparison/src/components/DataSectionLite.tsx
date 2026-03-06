import React from 'react';
import type { DataRow } from '../data';

/**
 * DataSection using dangerouslySetInnerHTML for the table body.
 * Reduces ~200 elements (20 rows × 8 cells + headers + footer) to a single write.
 */
export default function DataSectionLite({ columns, rows }: { columns: string[]; rows: DataRow[] }) {
  const headerHtml = '<tr>' + columns.map((c) => `<th class="data-th">${c}</th>`).join('') + '</tr>';

  const bodyHtml = rows.map((row, i) =>
    `<tr class="${i % 2 === 0 ? 'row-even' : 'row-odd'}">${columns.map((col) => `<td class="data-td">${row[col]}</td>`).join('')}</tr>`
  ).join('');

  const numericCols = columns.slice(1);
  const footerHtml = '<tr><td class="data-td">Totals</td>' +
    numericCols.map((col) => {
      const nums = rows.map((r) => Number(r[col])).filter((v) => !isNaN(v));
      const total = nums.length > 0 ? nums.reduce((a, b) => a + b, 0) : '';
      return `<td class="data-td">${total || '-'}</td>`;
    }).join('') + '</tr>';

  const tableHtml = `<thead>${headerHtml}</thead><tbody>${bodyHtml}</tbody><tfoot>${footerHtml}</tfoot>`;

  return (
    <section className="data-section">
      <h2 className="section-title">Sales Comparison Data</h2>
      <div className="data-table-wrapper">
        <table
          className="data-table"
          dangerouslySetInnerHTML={{ __html: tableHtml }}
        />
      </div>
    </section>
  );
}
