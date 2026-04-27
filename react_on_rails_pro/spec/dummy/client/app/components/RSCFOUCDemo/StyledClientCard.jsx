'use client';

import React from 'react';
import styles from './StyledClientCard.module.scss';

const StyledClientCard = ({ message }) => (
  <div className={styles.card} data-testid="styled-client-card">
    <span className={styles.label}>{message}</span>
  </div>
);

export default StyledClientCard;
