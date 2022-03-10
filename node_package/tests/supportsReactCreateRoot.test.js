import ReactDOM from 'react-dom';
import { isVersionGreaterThanOrEqualTo18 } from '../src/supportsReactCreateRoot';

describe('supportsReactCreateRoot', () => {
  it('returns false for ReactDOM v16, no version', () => {
    expect.assertions(1);
    const originalValue = ReactDOM.version;
    delete ReactDOM.version;
    expect(isVersionGreaterThanOrEqualTo18()).toBe(false);
    ReactDOM.version = originalValue;
  });

  it('returns false for ReactDOM v17', () => {
    const originalValue = ReactDOM.version;
    ReactDOM.version = '17.0.0';
    expect.assertions(1);
    expect(isVersionGreaterThanOrEqualTo18()).toBe(false);
    ReactDOM.version = originalValue;
  });

  it('returns true for ReactDOM v18', () => {
    expect.assertions(1);
    const originalValue = ReactDOM.version;
    ReactDOM.version = '18.0.0';
    expect(isVersionGreaterThanOrEqualTo18()).toBe(true);
    ReactDOM.version = originalValue;
  });

  it('returns true for ReactDOM v19', () => {
    expect.assertions(1);
    const originalValue = ReactDOM.version;
    ReactDOM.version = '19.0.0';
    expect(isVersionGreaterThanOrEqualTo18()).toBe(true);
    ReactDOM.version = originalValue;
  });

  it('returns true for ReactDOM v18 beta', () => {
    expect.assertions(1);
    const originalValue = ReactDOM.version;
    ReactDOM.version = '18.0.0-rc.2';
    expect(isVersionGreaterThanOrEqualTo18()).toBe(true);
    ReactDOM.version = originalValue;
  });
});
