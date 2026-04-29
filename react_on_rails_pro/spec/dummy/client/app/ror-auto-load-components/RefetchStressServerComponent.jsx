import React from 'react';
import InlineRefreshButton from '../components/InlineRefreshButton';

/**
 * A server component used by the RefetchStressPage example. Returns content
 * that visibly changes between fetches: a server-side timestamp + a random
 * token. Optionally embeds an InlineRefreshButton inside the RSC subtree so
 * the demo can exercise useCurrentRSCRoute() from a client descendant.
 */
const RefetchStressServerComponent = ({ label = 'card', includeInlineButton = false }) => {
  const ts = new Date().toISOString();
  const token = Math.random().toString(36).slice(2, 8);
  return (
    <div
      data-testid={`stress-card-${label}`}
      style={{
        border: '1px solid #888',
        padding: '8px',
        margin: '8px 0',
        borderRadius: '4px',
        background: '#fafafa',
      }}
    >
      <div>
        <strong>{label}</strong>
      </div>
      <div>
        Server time: <span data-testid={`stress-time-${label}`}>{ts}</span>
      </div>
      <div>
        Token: <span data-testid={`stress-token-${label}`}>{token}</span>
      </div>
      {includeInlineButton ? (
        <div style={{ marginTop: '8px' }}>
          <InlineRefreshButton testId={`stress-inline-${label}`} />
        </div>
      ) : null}
    </div>
  );
};

export default RefetchStressServerComponent;
