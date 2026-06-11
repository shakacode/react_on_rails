'use client';

import React from 'react';
import styles from './css-modules-probe.module.css';

const CssModulesProbe = () => (
  <div className={styles.probe} data-testid="css-probe-modules">
    CSS Modules (.module.css)
  </div>
);

export default CssModulesProbe;
