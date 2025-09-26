import * as React from 'react';
import Outlet from '../components/RouterOutlet';
// @ts-expect-error - ToggleContainer is a JavaScript file without TypeScript types
import ToggleContainer from '../components/RSCPostsPage/ToggleContainerForServerComponents';

export default function ServerComponentRouterLayout() {
  return (
    <div>
      <h1>Server Component Router Layout</h1>
      <p>This is the layout for the server component router.</p>
      <p>The following is the content of the server component router child route:</p>
      <ToggleContainer childrenTitle="sub-route">
        <React.Suspense fallback={<div>Loading sub-route...</div>}>
          <Outlet />
        </React.Suspense>
      </ToggleContainer>
    </div>
  );
}
