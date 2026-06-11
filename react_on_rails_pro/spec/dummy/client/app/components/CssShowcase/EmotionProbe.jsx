'use client';

import React from 'react';
import styled from '@emotion/styled';

const ProbeDiv = styled.div`
  display: inline-flex;
  align-items: center;
  padding: 0.5rem 1rem;
  margin: 0.25rem;
  border: 2px solid rgb(100, 150, 170);
  background-color: rgb(176, 224, 230);
  color: rgb(20, 50, 60);
  font-weight: 600;
`;

const EmotionProbe = () => (
  <ProbeDiv data-testid="css-probe-emotion">
    Emotion (CSS-in-JS)
  </ProbeDiv>
);

export default EmotionProbe;
