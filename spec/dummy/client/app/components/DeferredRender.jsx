import React from 'react';
import { Link } from 'react-router';

const DeferredRender = ({ children }) => (
  <div>
    <h1>Deferred Rendering</h1>
    <p>
      Here, we're testing async routes with server rendering.
      By deferring the initial render, we can prevent a client/server
      checksum mismatch error.
    </p>
    {
      children ? children : (
        <p>
          <Link to="/deferred_render_with_server_rendering/async_page">
            Test Async Route
          </Link>
        </p>
      )
    }
  </div>
);

export default DeferredRender;
