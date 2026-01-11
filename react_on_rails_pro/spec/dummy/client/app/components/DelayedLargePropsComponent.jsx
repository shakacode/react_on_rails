/**
 * DelayedLargePropsComponent - Test component registered after a delay
 *
 * This component is identical to LargePropsComponent but its bundle registration
 * is delayed to simulate code-splitting scenarios where bundles load asynchronously.
 *
 * The delay creates a window where:
 * 1. The server renders the component placeholder with JSON props in script tag
 * 2. React on Rails Pro's immediate hydration captures the element
 * 3. The component bundle is registered (after delay)
 * 4. JSON.parse is called on el.textContent
 *
 * If there's a race condition, the textContent might be corrupted by this point.
 *
 * Issue: https://github.com/shakacode/react_on_rails/issues/2283
 */

import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

const DelayedLargePropsComponent = ({ largeData, componentId, loadTime, registrationDelay }) => {
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
        console.error('[DelayedLargePropsComponent] Invalid props structure:', {
          componentId,
          hasLargeData: !!largeData,
          hasItems: largeData ? Array.isArray(largeData.items) : false,
          itemsLength: largeData?.items?.length,
          hasSummary: largeData ? typeof largeData.summary === 'object' : false,
        });
      }
    } catch (e) {
      console.error('[DelayedLargePropsComponent] Error validating props:', e);
      setPropsValid(false);
    }
  }, [largeData, componentId]);

  // Calculate props size
  const propsSize = largeData ? JSON.stringify(largeData).length : 0;
  const itemCount = largeData?.items?.length || 0;

  return (
    <div
      data-testid={`delayed-large-props-component-${componentId}`}
      style={{
        border: '2px dashed #ff9800',
        padding: '10px',
        margin: '10px 0',
        backgroundColor: propsValid ? '#fff3e0' : '#ffebee',
      }}
    >
      <h3>Delayed Large Props Component #{componentId}</h3>
      <p>
        <em>(Registered with {registrationDelay}ms delay)</em>
      </p>
      <p>Props size: {(propsSize / 1024).toFixed(2)} KB</p>
      <p>Items count: {itemCount}</p>
      <p>Load time (from server): {loadTime}</p>
      <p>Render time (client): {renderTime || 'Loading...'}</p>
      <p data-testid="delayed-status" style={{ color: propsValid ? 'green' : 'red', fontWeight: 'bold' }}>
        Status: {propsValid ? 'Rendered Successfully' : 'INVALID PROPS'}
      </p>
      {!propsValid && (
        <p style={{ color: 'red' }}>
          Warning: Props validation failed. This may indicate a JSON parsing issue caused by the race
          condition with delayed registration.
        </p>
      )}
    </div>
  );
};

DelayedLargePropsComponent.propTypes = {
  largeData: PropTypes.shape({
    items: PropTypes.array.isRequired,
    summary: PropTypes.object.isRequired,
  }).isRequired,
  componentId: PropTypes.number.isRequired,
  loadTime: PropTypes.string.isRequired,
  registrationDelay: PropTypes.number.isRequired,
};

export default DelayedLargePropsComponent;
