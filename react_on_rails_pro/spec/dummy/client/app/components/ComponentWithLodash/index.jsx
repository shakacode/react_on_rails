import React from 'react';
import fp from 'lodash/fp';
import css from './index.module.scss';

export default function () {
  const paddedWord = fp.padStart(7)('works!');

  return (
    <div>
      <h3 className={css.message}>
        Lodash still
        {paddedWord}
      </h3>
    </div>
  );
}
