'use client';

import React, { useState } from 'react';

export default function FilterCheckbox({ label, defaultChecked = false }: { label: string; defaultChecked?: boolean }) {
  const [checked, setChecked] = useState(defaultChecked);

  return (
    <label className="filter-checkbox">
      <input
        type="checkbox"
        checked={checked}
        onChange={() => setChecked(!checked)}
      />
      <span className="checkbox-label">{label}</span>
    </label>
  );
}
