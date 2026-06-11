'use client';

import React from 'react';
import styles from './scss-modules-probe.module.scss';

const ScssModulesProbe = () => (
  <div className={styles.probe} data-testid="css-probe-scss">
    SCSS Modules (.module.scss)
  </div>
);

export default ScssModulesProbe;
