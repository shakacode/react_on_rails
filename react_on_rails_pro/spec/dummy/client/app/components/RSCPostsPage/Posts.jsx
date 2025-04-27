import React from 'react';
import fetch from 'node-fetch';
import _ from 'lodash';
import Post from './Post';

const Posts = async ({ artificialDelay, postsCount = 2 }) => {
  await new Promise((resolve) => {
    setTimeout(resolve, artificialDelay);
  });
  const posts = await (await fetch(`http://localhost:3000/api/posts`)).json();
  const postsByUser = _.groupBy(posts, 'user_id');
  const onePostPerUser = _.map(postsByUser, (group) => group[0]);
  const postsToShow = onePostPerUser.slice(0, postsCount);

  return (
    <div>
      {postsToShow.map((post) => (
        <Post key={post.id} post={post} artificialDelay={artificialDelay} />
      ))}
    </div>
  );
};

export default Posts;
