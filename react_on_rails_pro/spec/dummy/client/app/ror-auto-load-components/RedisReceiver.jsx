import React, { Suspense } from 'react';
import ToggleContainer from '../components/RSCPostsPage/ToggleContainerForServerComponents';
import { listenToRequestData } from '../utils/redisReceiver';
import { ErrorBoundary } from '../components/ErrorBoundary';

const RedisItem = async ({ getValue, itemIndex }) => {
  const value = await getValue(`Item${itemIndex}`);
  return (
    <li className={`redis-item${itemIndex}`}>
      Value of &quot;Item{itemIndex + 1}&quot;: {value}
    </li>
  );
};

const RedisItemWithWrapper = ({ getValue, itemIndex }) => (
  <section className={`redis-item${itemIndex}-container`}>
    <Suspense
      fallback={
        <p className={`redis-item${itemIndex}-fallback`}>
          Waiting for the key &quot;Item{itemIndex + 1}&quot;
        </p>
      }
    >
      <RedisItem getValue={getValue} itemIndex={itemIndex} />
    </Suspense>
  </section>
);

// Convert it to async component and make tests control when it's rendered
// To test the page behavior when a client component is rendered asynchronously at the page
const AsyncToggleContainer = async ({ children, childrenTitle, getValue }) => {
  await getValue('ToggleContainer');
  return <ToggleContainer childrenTitle={childrenTitle}>{children}</ToggleContainer>;
};

const RedisReceiver = ({ requestId, asyncToggleContainer }, railsContext) => {
  const { getValue, destroy } = listenToRequestData(requestId);

  if ('addPostSSRHook' in railsContext) {
    railsContext.addPostSSRHook(destroy);
  }

  const UsedToggleContainer = asyncToggleContainer ? AsyncToggleContainer : ToggleContainer;

  return () => (
    <ErrorBoundary>
      <main className="redis-receiver-container">
        <h1 className="redis-receiver-header">A list of items received from Redis:</h1>
        <Suspense fallback={<div>Loading ToggleContainer</div>}>
          <UsedToggleContainer childrenTitle="Redis Items" {...(asyncToggleContainer ? { getValue } : {})}>
            <ol className="redis-items-container">
              {[0, 1, 2, 3, 4].map((index) => (
                <RedisItemWithWrapper key={index} getValue={getValue} itemIndex={index} />
              ))}
            </ol>
          </UsedToggleContainer>
        </Suspense>
      </main>
    </ErrorBoundary>
  );
};

export default RedisReceiver;
