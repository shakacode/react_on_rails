import React, { Suspense } from 'react';
import ToggleContainer from '../components/RSCPostsPage/ToggleContainerForServerComponents';
import { listenToRequestData } from '../utils/redisReceiver';
import { ErrorBoundary } from '../components/ErrorBoundary';

const RedisItem = async ({ getValue, itemIndex }) => {
  const value = await getValue(`Item${itemIndex}`);
  return <li className={`redis-item${itemIndex}`}>Value of "Item{itemIndex + 1}": {value}</li>
}

const RedisItemWithWrapper = ({ getValue, itemIndex }) => (
  <section class={`redis-item${itemIndex}-container`}>
    <Suspense fallback={<p className={`redis-item${itemIndex}-fallback`}>Waiting for the key "Item{itemIndex + 1}"</p>}>
      <RedisItem getValue={getValue} itemIndex={itemIndex} />
    </Suspense>
  </section>
)

// Convert it to async component and make tests control when it's rendered
// To test the page behavior when a client component is rendered asynchronously at the page
const AsyncToggleContainer = async ({ children, childrenTitle, getValue }) => {
  await getValue('ToggleContainer');
  return <ToggleContainer children={children} childrenTitle={childrenTitle} />
}

const RedisReceiver = ({ requestId, asyncToggleContainer }, railsContext) => {
  const { getValue, close } = listenToRequestData(requestId);

  if ('addPostSSRHook' in railsContext) {
    railsContext.addPostSSRHook(close);
  }

  const UsedToggleContainer = asyncToggleContainer ? AsyncToggleContainer : ToggleContainer;

  return (
    <ErrorBoundary>
      <main className='redis-receiver-container'>
        <h1 className="redis-receiver-header">A list of items received from Redis:</h1>
        <UsedToggleContainer childrenTitle="Redis Items">
          <ol className='redis-items-container'>
            {
              [0,1,2,3,4].map(index => <RedisItemWithWrapper key={index} getValue={getValue} itemIndex={index} />)
            }
          </ol>
        </UsedToggleContainer>
      </main>
    </ErrorBoundary>
  )
}

export default RedisReceiver;