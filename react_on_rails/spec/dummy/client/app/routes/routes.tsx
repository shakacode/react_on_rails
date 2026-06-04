import React from 'react';
import { Routes, Route } from 'react-router-dom';

import RouterLayout from '../components/RouterLayout';

const routes = (
  <Routes>
    <Route path="/react_router/*" element={<RouterLayout />} />
  </Routes>
);

export default routes;
