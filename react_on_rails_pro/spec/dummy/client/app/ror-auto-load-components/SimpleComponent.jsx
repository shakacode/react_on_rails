import React, { Suspense } from 'react';
import SimpleClientComponent from '../components/SimpleClientComponent.jsx';

const Post = async ({ postPromise }) => {
  const post = await postPromise;
  return (
    <div>
      <h1>{post.title}</h1>
      <SimpleClientComponent content={post.content} />
    </div>
  );
};

const SimpleComponent = () => {
  const postPromise = Promise.resolve({
    title: 'Post 1',
    content: 'Content 1',
  });
  return (
    <Suspense fallback={<div>Loading Post...</div>}>
      <Post postPromise={postPromise} />
    </Suspense>
  );
};

export default SimpleComponent;
