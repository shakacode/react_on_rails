import React from 'react';

import styles from '../components/CssModulesImagesFontsExample.module.scss';

type CssModulesImagesFontsExampleProps = Record<string, never>;

const CssModulesImagesFontsExample = (_props: CssModulesImagesFontsExampleProps) => (
  <div>
    <h1 className={styles.heading}>This should be open sans light green.</h1>
    <div>
      <h2>Hookipa Beach image (relative path)</h2>
      <div className={styles.beachImage} />
    </div>
    <div>
      <h2>Check (URL encoded)</h2>
      <div className={styles.check} />
    </div>
    <div>
      <h2>Rails on Maui Logo (absolute path)</h2>
      <div className={styles.railsOnMaui} />
    </div>
  </div>
);

export default CssModulesImagesFontsExample;
