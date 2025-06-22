import React from 'react';
import ReactOnRails from 'react-on-rails';
import RSCPostsPage from '../components/RSCPostsPage/Main';
import { listenToRequestData } from '../utils/redisReceiver';

const RSCPostsPageOverRedis = ({ requestId, ...props }, railsContext) => {
  const { getValue, close } = listenToRequestData(requestId);

  const fetchPosts = () => getValue('posts');
  const fetchComments = (postId) => getValue(`comments:${postId}`);
  const fetchUser = (userId) => getValue(`user:${userId}`);

  ReactOnRails.addPostSSRHook(railsContext, close);

  return () => (
    <RSCPostsPage {...props} fetchPosts={fetchPosts} fetchComments={fetchComments} fetchUser={fetchUser} />
  );
};

export default RSCPostsPageOverRedis;
