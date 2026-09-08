import React, { useState } from 'react';

const BENCHMARK_MARKER = 'benchmark-initial';

const HelloWorld = () => {
  const [inputValue, setInputValue] = useState('');

  return (
    <main>
      <h1>Matched Rails React starter</h1>
      <p data-benchmark-marker>{BENCHMARK_MARKER}</p>
      <label htmlFor="benchmark-input">
        State preservation probe
        <input
          data-benchmark-input
          id="benchmark-input"
          value={inputValue}
          onChange={(event) => setInputValue(event.target.value)}
        />
      </label>
    </main>
  );
};

export default HelloWorld;
