import React, { Suspense } from 'react';
import { Routes, Route, Link } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
// @ts-expect-error - EchoProps is a JavaScript file without TypeScript types
import EchoProps from './EchoProps';
import { ErrorBoundary } from './ErrorBoundary';
import ServerComponentWithRetry from './ServerComponentWithRetry';

export default function App({ basePath = '/server_router', ...props }: { basePath?: string }) {
  return (
    <ErrorBoundary>
      <nav>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          <li>
            <Link to={`${basePath}/simple-server-component`}>Simple Server Component</Link>
          </li>
          <li>
            <Link to={`${basePath}/another-server-component`}>Another Simple Server Component</Link>
          </li>
          <li>
            <Link to={`${basePath}/client-component`}>Client Component</Link>
          </li>
          <li>
            <Link to={`${basePath}/complex-server-component`}>Complex Server Component</Link>
          </li>
          <li>
            <Link to={`${basePath}/nested-router`}>Server Component With Empty Sub Router</Link>
          </li>
          <li>
            <Link to={`${basePath}/nested-router/simple-server`}>
              Server Component with Simple Server Component in sub route
            </Link>
          </li>
          <li>
            <Link to={`${basePath}/nested-router/client-component`}>
              Server Component with Client Component in sub route
            </Link>
          </li>
          <li>
            <Link to={`${basePath}/streaming-server-component`}>
              Server Component with visible streaming behavior
            </Link>
          </li>
          <li>
            <Link to={`${basePath}/redis-receiver-for-testing`}>Redis Receiver For Testing</Link>
          </li>
          <li>
            <Link to={`${basePath}/server-component-with-retry`}>Server Component with Retry</Link>
          </li>
          <li>
            <Link to={`${basePath}/async-props-component`}>Async Props Component</Link>
          </li>
        </ul>
      </nav>
      <Suspense fallback={<div>Loading Page...</div>}>
        <Routes>
          <Route
            path={`${basePath}/simple-server-component`}
            element={<RSCRoute componentName="SimpleComponent" componentProps={{}} />}
          />
          <Route
            path={`${basePath}/another-server-component`}
            element={<RSCRoute componentName="MyServerComponent" componentProps={{}} />}
          />
          <Route path={`${basePath}/client-component`} element={<EchoProps {...props} />} />
          <Route
            path={`${basePath}/complex-server-component`}
            element={<RSCRoute componentName="RSCPostsPageOverHTTP" componentProps={props} />}
          />
          <Route
            path={`${basePath}/nested-router`}
            element={<RSCRoute componentName="ServerComponentRouterLayout" componentProps={props} />}
          >
            <Route
              path="simple-server"
              element={<RSCRoute componentName="SimpleComponent" componentProps={{}} />}
            />
            <Route path="client-component" element={<EchoProps {...props} />} />
          </Route>
          <Route
            path={`${basePath}/redis-receiver-for-testing`}
            element={<RSCRoute componentName="RedisReceiver" componentProps={props} />}
          />
          <Route
            path={`${basePath}/streaming-server-component`}
            element={<RSCRoute componentName="AsyncComponentsTreeForTesting" componentProps={props} />}
          />
          <Route path={`${basePath}/server-component-with-retry`} element={<ServerComponentWithRetry />} />
          <Route
            path={`${basePath}/async-props-component`}
            element={<RSCRoute componentName="AsyncPropsComponent" componentProps={props} />}
          />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}
