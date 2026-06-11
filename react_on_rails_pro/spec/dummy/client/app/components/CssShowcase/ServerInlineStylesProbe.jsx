import React from 'react';

const probeStyle = {
  display: 'inline-flex',
  alignItems: 'center',
  padding: '0.5rem 1rem',
  margin: '0.25rem',
  border: '2px solid rgb(120, 120, 180)',
  backgroundColor: 'rgb(200, 200, 230)',
  color: 'rgb(20, 20, 60)',
  fontWeight: 600,
};

const ServerInlineStylesProbe = () => (
  <div style={probeStyle} data-testid="css-probe-server-inline">
    Inline Styles in Server Component
  </div>
);

export default ServerInlineStylesProbe;
