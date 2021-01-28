import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import routes from '../routes/routes';

export default (props) => <BrowserRouter {...props}>{routes}</BrowserRouter>;
