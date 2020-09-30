/* eslint-disable react/prop-types */
import React from 'react';

import styles from './CssModulesImagesFontsExample.module.scss';

export default (_props) => (
  <div>
    justin
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



        Why doesn't the next line have any style
        check the div has no style uuuuuuu
      <div className={styles.railsOnMaui} />
    </div>
  </div>
);
