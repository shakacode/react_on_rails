import React from 'react';
import { Routes, Route } from 'react-router-dom';

import RouterLayout from '../components/RouterLayout';

export default (
  <Routes>
    <Route path="/react_router/*" element={<RouterLayout />} />
  </Routes>
);
