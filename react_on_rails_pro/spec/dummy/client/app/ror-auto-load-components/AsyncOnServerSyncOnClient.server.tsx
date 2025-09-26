'use client';

import wrapServerComponentRenderer from 'react-on-rails/wrapServerComponentRenderer/server';
import AsyncOnServerSyncOnClient from '../components/AsyncOnServerSyncOnClient';

export default wrapServerComponentRenderer(AsyncOnServerSyncOnClient);
