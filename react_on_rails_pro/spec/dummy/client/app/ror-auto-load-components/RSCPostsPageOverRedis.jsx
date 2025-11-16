import React from 'react';
import RSCPostsPage from '../components/RSCPostsPage/Main';
import { listenToRequestData } from '../utils/redisReceiver';

const RSCPostsPageOverRedis = ({ requestId, ...props }, railsContext) => {
  const { getValue, destroy } = listenToRequestData(requestId);

  const fetchPosts = () => getValue('posts');
  const fetchComments = (postId) => getValue(`comments:${postId}`);
  const fetchUser = (userId) => getValue(`user:${userId}`);

  if ('addPostSSRHook' in railsContext) {
    railsContext.addPostSSRHook(destroy);
  }

  return () => (
    <RSCPostsPage {...props} fetchPosts={fetchPosts} fetchComments={fetchComments} fetchUser={fetchUser} />
  );
};

export default RSCPostsPageOverRedis;
