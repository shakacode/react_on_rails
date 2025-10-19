import React, { Suspense } from 'react';
import { listenToRequestData } from '../utils/redisReceiver';
import { ErrorBoundary } from '../components/ErrorBoundary';

const RedisItem = async ({ getValue, redisKey }) => {
  const value = await getValue(redisKey);
  return <p>Value of "{redisKey}": {value}</p>
}

const RedisItemWithWrapper = ({ getValue, redisKey }) => (
  <Suspense fallback={<p>Waiting for the key "{redisKey}"</p>}>
    <RedisItem getValue={getValue} redisKey={redisKey} />
  </Suspense>
)

const RedisReceiver = ({ requestId }, railsContext) => {
  const { getValue, close } = listenToRequestData(requestId);

  if ('addPostSSRHook' in railsContext) {
    railsContext.addPostSSRHook(close);
  }

  return (
    <ErrorBoundary>
      <h1>A list of items received from Redis:</h1>
      <ol>
        {
          [1,2,3,4,5].map(index => <RedisItemWithWrapper key={index} getValue={getValue} redisKey={`Item${index}`} />)
        }
      </ol>
    </ErrorBoundary>
  )
}

export default RedisReceiver;