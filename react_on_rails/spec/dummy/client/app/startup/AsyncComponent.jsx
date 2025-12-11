import PropTypes from 'prop-types';
import React from 'react';

/**
 * A simple component used to test the reactOnRailsPageLoaded() behavior
 * when called multiple times (e.g., for asynchronously loaded content).
 *
 * This component is client-side only (prerender: false), meaning the DOM node
 * is initially empty. When reactOnRailsPageLoaded() is called again after the
 * component has already been rendered, it should NOT try to hydrate.
 */
const AsyncComponent = ({ name }) => {
  // Use inline styles to verify that hydration issues would cause CSS property
  // format mismatches (camelCase in React vs kebab-case in server HTML)
  const containerStyle = {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    padding: '20px',
    marginTop: '10px',
    backgroundColor: '#f0f0f0',
    borderRadius: '8px',
  };

  return (
    <div style={containerStyle} data-testid="async-component">
      <h3>Async Component: {name}</h3>
      <p>This component was loaded and rendered client-side.</p>
      <p>If you see hydration errors, the fix for issue #2210 is not working.</p>
    </div>
  );
};

AsyncComponent.propTypes = {
  name: PropTypes.string.isRequired,
};

export default AsyncComponent;
