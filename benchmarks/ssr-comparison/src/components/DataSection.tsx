import React from 'react';
import type { DataRow } from '../data';

export default function DataSection({ columns, rows }: { columns: string[]; rows: DataRow[] }) {
  return (
    <section className="data-section">
      <h2 className="section-title">Sales Comparison Data</h2>
      <div className="data-table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              {columns.map((col) => (
                <th key={col} className="data-th">{col}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr key={i} className={i % 2 === 0 ? 'row-even' : 'row-odd'}>
                {columns.map((col) => (
                  <td key={col} className="data-td">{row[col]}</td>
                ))}
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr>
              <td className="data-td">Totals</td>
              {columns.slice(1).map((col) => {
                const numericVals = rows.map((r) => Number(r[col])).filter((v) => !isNaN(v));
                const total = numericVals.length > 0 ? numericVals.reduce((a, b) => a + b, 0) : '';
                return <td key={col} className="data-td">{total || '-'}</td>;
              })}
            </tr>
          </tfoot>
        </table>
      </div>
    </section>
  );
}
