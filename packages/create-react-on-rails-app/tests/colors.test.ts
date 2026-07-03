/**
 * Regression tests for the color-enable decision in src/utils.ts.
 *
 * The `pc` color instance is built at module load from the environment, layering
 * one chalk-compatibility override (FORCE_COLOR=0/false disables) on top of
 * picocolors' own detection. That override has already been wrong twice in this
 * package's history — FORCE_COLOR=0 wrongly enabling color, and empty NO_COLOR=
 * being mishandled — so this suite locks the decision across the env matrix.
 *
 * `pc` is a module-load-time const and picocolors reads process.env when it is
 * first required, so each case runs in an isolated module registry
 * (jest.isolateModules) with process.env mutated first, then re-requires utils.
 */

const ANSI_RED_OPEN = '[31m';

function colorEnabledUnder(env: NodeJS.ProcessEnv): boolean {
  let enabled = false;
  jest.isolateModules(() => {
    // Re-require inside the isolated registry so both picocolors and utils
    // re-read the freshly mutated process.env.
    // eslint-disable-next-line @typescript-eslint/no-var-requires, global-require
    const { pc } = require('../src/utils') as typeof import('../src/utils');
    enabled = pc.red('x').includes(ANSI_RED_OPEN);
  });
  return enabled;
}

describe('pc color-enable decision', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    // Deterministic non-color baseline that does not depend on the test runner's
    // TTY/CI: no TTY (jest's stdout isn't a TTY anyway), and explicitly clear the
    // vars picocolors keys off so each case sets only what it is testing.
    const base = { ...originalEnv };
    delete base.FORCE_COLOR;
    delete base.NO_COLOR;
    delete base.CI;
    delete base.TERM;
    process.env = base;
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('enables color when FORCE_COLOR=1', () => {
    process.env.FORCE_COLOR = '1';
    expect(colorEnabledUnder(process.env)).toBe(true);
  });

  it('disables color when FORCE_COLOR=0 (chalk-compat override)', () => {
    process.env.FORCE_COLOR = '0';
    expect(colorEnabledUnder(process.env)).toBe(false);
  });

  it('disables color when FORCE_COLOR=false (chalk-compat override)', () => {
    process.env.FORCE_COLOR = 'false';
    expect(colorEnabledUnder(process.env)).toBe(false);
  });

  it('disables color when NO_COLOR=1', () => {
    process.env.NO_COLOR = '1';
    expect(colorEnabledUnder(process.env)).toBe(false);
  });

  it('disables color by default in a non-TTY, non-CI environment', () => {
    // base already cleared FORCE_COLOR/NO_COLOR/CI; jest stdout is not a TTY.
    expect(colorEnabledUnder(process.env)).toBe(false);
  });
});
