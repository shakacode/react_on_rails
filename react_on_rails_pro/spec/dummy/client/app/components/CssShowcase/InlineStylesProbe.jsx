'use client';

import React from 'react';

const probeStyle = {
  display: 'inline-flex',
  alignItems: 'center',
  padding: '0.5rem 1rem',
  margin: '0.25rem',
  border: '2px solid rgb(100, 160, 100)',
  backgroundColor: 'rgb(200, 230, 201)',
  color: 'rgb(20, 60, 20)',
  fontWeight: 600,
};

const InlineStylesProbe = () => (
  <div style={probeStyle} data-testid="css-probe-inline">
    Inline Styles (style prop)
  </div>
);

export default InlineStylesProbe;
