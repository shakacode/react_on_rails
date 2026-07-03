/**
 * Regression tests for the color-enable decision in src/utils.ts.
 *
 * The `pc` color instance is built at module load by reproducing chalk@4's
 * colorize/plain precedence (FORCE_COLOR wins, then NO_COLOR, then TTY) rather
 * than deferring to picocolors' own detection, which uses a different precedence.
 * This decision has regressed repeatedly in the package's history — FORCE_COLOR=0
 * wrongly enabling color, empty NO_COLOR= mishandling, a bare CI forcing color in
 * piped output, and NO_COLOR overriding an explicit FORCE_COLOR — so this suite
 * locks the full matrix.
 *
 * `pc` is a module-load-time const, so each case runs in an isolated module
 * registry (jest.isolateModules) after mutating the environment, then re-requires
 * utils. TTY state is stubbed explicitly so the result never depends on the runner.
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

  // Use plain assignment rather than Object.defineProperty: other suites (e.g.
  // index-tty.test.ts) define process.stdout.isTTY as a non-configurable data
  // property, and a later defineProperty would throw "Cannot redefine property".
  // Assignment works whether isTTY is a writable data property or absent.
  function setTTY(isTTY: boolean | undefined): void {
    (process.stdout as { isTTY?: boolean }).isTTY = isTTY;
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
    setTTY(originalIsTTY);
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

  it('lets an explicit FORCE_COLOR=1 override NO_COLOR (chalk precedence)', () => {
    // chalk@4 treats a present, non-zero FORCE_COLOR as a hard override that wins
    // over NO_COLOR; picocolors would let NO_COLOR disable, so this locks the order.
    process.env.NO_COLOR = '1';
    process.env.FORCE_COLOR = '1';
    expect(colorEnabled()).toBe(true);
  });

  it('treats an empty FORCE_COLOR= as force-on (chalk precedence)', () => {
    process.env.FORCE_COLOR = '';
    expect(colorEnabled()).toBe(true);
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

  it('disables color on Windows with non-TTY stdout and no color vars', () => {
    // picocolors enables color for `process.platform === 'win32'` regardless of
    // TTY; chalk@4 required a TTY/FORCE_COLOR first. Guards ANSI escapes in
    // redirected Windows output (e.g. `create-react-on-rails-app app > log.txt`).
    const originalPlatform = process.platform;
    Object.defineProperty(process, 'platform', { value: 'win32', configurable: true });
    try {
      expect(colorEnabled()).toBe(false);
    } finally {
      Object.defineProperty(process, 'platform', { value: originalPlatform, configurable: true });
    }
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
