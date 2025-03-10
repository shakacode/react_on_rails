import React, { Suspense } from 'react';
import { ErrorBoundary } from '../components/ErrorBoundary';
import Posts from '../components/RSCPostsPage/Posts';
import HelloWorld from '../components/HelloWorldHooks.jsx';
import ErrorComponent from '../components/ErrorComponent.jsx';
import Spinner from '../components/Spinner.jsx';

const RSCPostsPage = ({ artificialDelay, postsCount, ...props }) => {
  return (
    <ErrorBoundary FallbackComponent={ErrorComponent}>
      <div>
        <HelloWorld {...props} />
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold' }}>RSC Posts Page</h1>
        <Suspense fallback={<Spinner />}>
          <Posts artificialDelay={artificialDelay} postsCount={postsCount} />
        </Suspense>
      </div>
    </ErrorBoundary>
  );
};

export default RSCPostsPage;
