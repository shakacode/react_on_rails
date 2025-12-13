import PropTypes from 'prop-types';
import React from 'react';

/**
 * A simple component used to test the reactOnRailsPageLoaded() behavior
 * when called multiple times for manually/dynamically rendered content.
 *
 * This component is client-side only (prerender: false), meaning the DOM node
 * is initially empty. When reactOnRailsPageLoaded() is called again after the
 * component has already been rendered, it should NOT try to hydrate.
 *
 * Note: This tests the core package's manual rendering API, not Pro's async hydration.
 */
const ManualRenderComponent = ({ name }) => {
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
    <div style={containerStyle} data-testid="manual-render-component">
      <h3>Manual Render Component: {name}</h3>
      <p>This component was loaded and rendered client-side via manual API call.</p>
      <p>If you see hydration errors, the fix for issue #2210 is not working.</p>
    </div>
  );
};

ManualRenderComponent.propTypes = {
  name: PropTypes.string.isRequired,
};

export default ManualRenderComponent;
