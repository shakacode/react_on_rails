import React, { Suspense } from 'react';
import fetch from 'node-fetch';
import SimpleClientComponent from '../components/SimpleClientComponent.jsx';

const Post = async () => {
  const post = await (await fetch('https://jsonplaceholder.org/posts/1')).json();
  return (
    <div>
      <h1>{post.title}</h1>
      <SimpleClientComponent content={post.content} />
    </div>
  );
};

const SimpleComponent = () => {
  return (
    <Suspense fallback={<div>Loading Post...</div>}>
      <Post />
    </Suspense>
  );
};

export default SimpleComponent;
