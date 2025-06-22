import React, { Suspense } from 'react';
import { ErrorBoundary } from '../ErrorBoundary';
import Posts from './Posts';
import HelloWorld from '../HelloWorldHooksForServerComponents';
import Spinner from '../Spinner';

const RSCPostsPage = ({ artificialDelay, postsCount, fetchPosts, fetchComments, fetchUser, ...props }) => {
  return (
    <ErrorBoundary>
      <div>
        <HelloWorld {...props} />
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold' }}>RSC Posts Page</h1>
        <Suspense fallback={<Spinner />}>
          <Posts
            artificialDelay={artificialDelay}
            postsCount={postsCount}
            fetchPosts={fetchPosts}
            fetchComments={fetchComments}
            fetchUser={fetchUser}
          />
        </Suspense>
      </div>
    </ErrorBoundary>
  );
};

export default RSCPostsPage;
