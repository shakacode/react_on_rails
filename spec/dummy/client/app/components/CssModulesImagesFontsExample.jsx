/* eslint-disable react/prop-types */
import React from 'react';

import styles from './CssModulesImagesFontsExample.scss'

export default (_props, _railsContext) => (
  <div>
    <h1 className={styles.heading}>This should be open sans light</h1>
    <div>
      <h2>
        Last Call (relative path)
      </h2>
      <div className={styles.lastCall}/>
    </div>
    <div>
      <h2>
        Check (URL encoded)
      </h2>
      <div className={styles.check}/>
    </div>
    <div>
      <h2>
        Rails on Maui Logo (absolute path)
      </h2>
      <div className={styles.railsOnMaui}/>
    </div>
  </div>
);
