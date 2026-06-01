'use client';

import React from 'react';
import styles from './UseClientCssProbe.module.scss';

const UseClientCssProbe = () => (
  <div className={styles.probe} data-testid="rsc-css-probe">
    RSC use-client CSS probe
  </div>
);

export default UseClientCssProbe;
