/* eslint-disable react/prop-types */
import React from 'react';

// The extra function wrapper is unnecessary here
export default (props) => () => <h1>{props.title}</h1>;
