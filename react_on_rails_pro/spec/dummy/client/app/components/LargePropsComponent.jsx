/**
 * LargePropsComponent - Test component for large props JSON parsing
 *
 * This component receives large props (~200KB) to test for race conditions
 * in JSON parsing when immediate hydration is enabled.
 *
 * Issue: https://github.com/shakacode/react_on_rails/issues/2283
 */

import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

const LargePropsComponent = ({ largeData, componentId, loadTime, registrationDelay }) => {
  const [renderTime, setRenderTime] = useState(null);
  const [propsValid, setPropsValid] = useState(false);

  // Set render time only on client to avoid hydration mismatch
  useEffect(() => {
    setRenderTime(new Date().toISOString());
  }, []);

  useEffect(() => {
    // Validate that props were correctly parsed
    try {
      const isValid =
        largeData &&
        Array.isArray(largeData.items) &&
        largeData.items.length > 0 &&
        typeof largeData.summary === 'object';

      setPropsValid(isValid);

      if (!isValid) {
        console.error('[LargePropsComponent] Invalid props structure:', {
          componentId,
          hasLargeData: !!largeData,
          hasItems: largeData ? Array.isArray(largeData.items) : false,
          itemsLength: largeData?.items?.length,
          hasSummary: largeData ? typeof largeData.summary === 'object' : false,
        });
      }
    } catch (e) {
      console.error('[LargePropsComponent] Error validating props:', e);
      setPropsValid(false);
    }
  }, [largeData, componentId]);

  // Calculate props size
  const propsSize = largeData ? JSON.stringify(largeData).length : 0;
  const itemCount = largeData?.items?.length || 0;

  return (
    <div
      data-testid={`large-props-component-${componentId}`}
      style={{
        border: '1px solid #ccc',
        padding: '10px',
        margin: '10px 0',
        backgroundColor: propsValid ? '#e8f5e9' : '#ffebee',
      }}
    >
      <h3>Large Props Component #{componentId}</h3>
      <p>Props size: {(propsSize / 1024).toFixed(2)} KB</p>
      <p>Items count: {itemCount}</p>
      <p>Load time (from server): {loadTime}</p>
      <p>Render time (client): {renderTime || 'Loading...'}</p>
      <p>Registration delay: {registrationDelay}ms</p>
      <p data-testid="status" style={{ color: propsValid ? 'green' : 'red', fontWeight: 'bold' }}>
        Status: {propsValid ? 'Rendered Successfully' : 'INVALID PROPS'}
      </p>
      {!propsValid && (
        <p style={{ color: 'red' }}>
          Warning: Props validation failed. This may indicate a JSON parsing issue.
        </p>
      )}
    </div>
  );
};

LargePropsComponent.propTypes = {
  largeData: PropTypes.shape({
    items: PropTypes.array.isRequired,
    summary: PropTypes.object.isRequired,
  }).isRequired,
  componentId: PropTypes.number.isRequired,
  loadTime: PropTypes.string.isRequired,
  registrationDelay: PropTypes.number.isRequired,
};

export default LargePropsComponent;
