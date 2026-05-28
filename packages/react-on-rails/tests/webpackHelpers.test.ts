import { reactDomClientWarning } from '../src/webpackHelpers.cts';

describe('webpackHelpers', () => {
  describe('reactDomClientWarning', () => {
    it('matches the webpack 5 "Module not found" warning for react-dom/client', () => {
      const message =
        "Module not found: Error: Can't resolve 'react-dom/client' in '/app/node_modules/react-on-rails/lib'";
      expect(reactDomClientWarning.test(message)).toBe(true);
    });

    it('matches the "Module not found" warning regardless of file path', () => {
      const message =
        "Module not found: Error: Can't resolve 'react-dom/client' in '/app/node_modules/react-on-rails/src'";
      expect(reactDomClientWarning.test(message)).toBe(true);
    });

    it('does not match unrelated module-not-found warnings', () => {
      expect(reactDomClientWarning.test("Module not found: Error: Can't resolve 'react-dom'")).toBe(false);
      expect(reactDomClientWarning.test("Module not found: Error: Can't resolve 'react-router/client'")).toBe(
        false,
      );
    });
  });
});
