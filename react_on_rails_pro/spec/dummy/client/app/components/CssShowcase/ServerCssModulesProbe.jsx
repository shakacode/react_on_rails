import React from 'react';
import styles from './server-css-modules-probe.module.css';

const ServerCssModulesProbe = () => (
  <div className={styles.probe} data-testid="css-probe-server-modules">
    CSS Modules in Server Component
  </div>
);

export default ServerCssModulesProbe;
