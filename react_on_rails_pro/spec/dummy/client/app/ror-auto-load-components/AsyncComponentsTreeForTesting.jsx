import React, { Suspense } from 'react';
import HelloWorldHooks from './HelloWorldHooks';

const AsyncComponentsBranch = ({ branchName, level }) => {
  const buildResult = () => {
    console.log(`${branchName} (level ${level})`);
    console.error('Error message', { branchName, level });
    if (level === 0) {
      return <div>{`${branchName} (level 0)`}</div>;
    }
    return (
      <div>
        <p>{`${branchName} (level ${level})`}</p>
        <Suspense
          fallback={
            <div>
              Loading {branchName} at level {level}...
            </div>
          }
        >
          <AsyncComponentsBranch branchName={branchName} level={level - 1} />
        </Suspense>
      </div>
    );
  };

  // On the client side, the component should not return a Promise.
  // Instead, consider the following best practices:
  // 1. Use React Server Components for async operations if possible.
  // 2. Implement client-side caching for async results to improve performance.
  if (typeof window !== 'undefined') {
    return buildResult();
  }
  return new Promise((resolve) => setTimeout(() => resolve(buildResult()), 1000));
};

const AsyncHelloWorldHooks = (props) => {
  if (typeof window !== 'undefined') {
    return <HelloWorldHooks {...props} />;
  }
  return new Promise((resolve) => setTimeout(() => resolve(<HelloWorldHooks {...props} />), 1000));
};

const AsyncComponentsTreeForTesting = (props) => {
  console.log('Sync console log from AsyncComponentsTreeForTesting');
  return (
    <div>
      <div>
        <p>Header for AsyncComponentsTreeForTesting</p>
      </div>
      <Suspense fallback={<div>Loading HelloWorldHooks...</div>}>
        <AsyncHelloWorldHooks {...props} />
      </Suspense>
      <Suspense fallback={<div>Loading branch1...</div>}>
        <AsyncComponentsBranch branchName="branch1" level={4} />
      </Suspense>
      <Suspense fallback={<div>Loading branch2...</div>}>
        <AsyncComponentsBranch branchName="branch2" level={1} />
      </Suspense>
      <div>
        <p>Footer for AsyncComponentsTreeForTesting</p>
      </div>
    </div>
  );
};

export default AsyncComponentsTreeForTesting;
