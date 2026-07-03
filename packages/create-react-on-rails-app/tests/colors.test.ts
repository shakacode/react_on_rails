/**
 * Regression tests for the color-enable decision in src/utils.ts.
 *
 * The `pc` color instance is built at module load from the environment, layering
 * two chalk@4-compatibility overrides on top of picocolors' own detection:
 * FORCE_COLOR=0/false disables, and a bare CI (non-TTY) does not force color.
 * Both behaviors have regressed in this package's history — FORCE_COLOR=0 wrongly
 * enabling color, empty NO_COLOR= mishandling, and CI-only output-incompatibility
 * — so this suite locks the decision across the env/TTY matrix.
 *
 * `pc` is a module-load-time const and picocolors reads process.env + stdout.isTTY
 * when first required, so each case runs in an isolated module registry
 * (jest.isolateModules) after mutating the environment, then re-requires utils.
 * TTY state is stubbed explicitly so the result never depends on the test runner.
 */

const ANSI_RED_OPEN = '[31m';

function colorEnabled(): boolean {
  let enabled = false;
  jest.isolateModules(() => {
    // Re-require inside the isolated registry so both picocolors and utils
    // re-read the freshly mutated process.env and process.stdout.isTTY.
    // eslint-disable-next-line @typescript-eslint/no-var-requires, global-require
    const { pc } = require('../src/utils') as typeof import('../src/utils');
    enabled = pc.red('x').includes(ANSI_RED_OPEN);
  });
  return enabled;
}

describe('pc color-enable decision', () => {
  const originalEnv = process.env;
  const originalIsTTY = process.stdout.isTTY;

  function setTTY(isTTY: boolean): void {
    Object.defineProperty(process.stdout, 'isTTY', { value: isTTY, configurable: true });
  }

  beforeEach(() => {
    // Deterministic baseline independent of the runner: clear every signal the
    // color decision keys off, and force a non-TTY stdout. Each test sets only
    // what it is exercising.
    const base = { ...originalEnv };
    delete base.FORCE_COLOR;
    delete base.NO_COLOR;
    delete base.CI;
    delete base.TERM;
    process.env = base;
    setTTY(false);
  });

  afterEach(() => {
    process.env = originalEnv;
    Object.defineProperty(process.stdout, 'isTTY', { value: originalIsTTY, configurable: true });
  });

  it('enables color when FORCE_COLOR=1', () => {
    process.env.FORCE_COLOR = '1';
    expect(colorEnabled()).toBe(true);
  });

  it('disables color when FORCE_COLOR=0 (chalk-compat override)', () => {
    process.env.FORCE_COLOR = '0';
    expect(colorEnabled()).toBe(false);
  });

  it('disables color when FORCE_COLOR=false (chalk-compat override)', () => {
    process.env.FORCE_COLOR = 'false';
    expect(colorEnabled()).toBe(false);
  });

  it('disables color when NO_COLOR=1', () => {
    process.env.NO_COLOR = '1';
    expect(colorEnabled()).toBe(false);
  });

  it('enables color for an interactive TTY (no CI, no FORCE_COLOR)', () => {
    setTTY(true);
    expect(colorEnabled()).toBe(true);
  });

  it('disables color for a bare CI with non-TTY stdout (chalk-compat override)', () => {
    // picocolors enables color on `!!env.CI` alone; chalk@4 stayed plain unless
    // FORCE_COLOR or a TTY was present. Guards ANSI leaking into captured CI logs.
    process.env.CI = 'true';
    expect(colorEnabled()).toBe(false);
  });

  it('still enables color in CI when FORCE_COLOR=1', () => {
    process.env.CI = 'true';
    process.env.FORCE_COLOR = '1';
    expect(colorEnabled()).toBe(true);
  });

  it('disables color by default in a non-TTY, non-CI environment', () => {
    expect(colorEnabled()).toBe(false);
  });
});
