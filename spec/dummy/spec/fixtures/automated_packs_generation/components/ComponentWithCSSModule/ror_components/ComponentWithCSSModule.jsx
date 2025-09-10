import React from 'react';
import styles from './ComponentWithCSSModule.module.css';

const ComponentWithCSSModule = () => {
  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Hello from CSS Module Component</h1>
    </div>
  );
};

export default ComponentWithCSSModule;
