// TEST FIXTURE: Always throws — used for error-path testing only.
// See /error_scenarios_hub for usage context.
import React from 'react';

const DeterministicRSCErrorComponent: React.FC = () => {
  throw new Error('Deterministic RSC error: always fails for error path testing');
};

export default DeterministicRSCErrorComponent;
