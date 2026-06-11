'use client';

import React from 'react';
import styled from 'styled-components';

const ProbeDiv = styled.div`
  display: inline-flex;
  align-items: center;
  padding: 0.5rem 1rem;
  margin: 0.25rem;
  border: 2px solid rgb(200, 150, 120);
  background-color: rgb(255, 218, 185);
  color: rgb(80, 40, 10);
  font-weight: 600;
`;

const StyledComponentsProbe = () => (
  <ProbeDiv data-testid="css-probe-styled-components">
    styled-components (CSS-in-JS)
  </ProbeDiv>
);

export default StyledComponentsProbe;
