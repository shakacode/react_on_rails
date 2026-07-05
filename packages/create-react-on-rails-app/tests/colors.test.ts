/**
 * Regression tests for the color-enable decision in src/utils.ts.
 *
 * The `pc` color instance is built at module load by reproducing chalk@4's
 * colorize/plain precedence (FORCE_COLOR wins, then NO_COLOR, then TTY plus a
 * chalk-compatible positive color signal) rather than deferring to picocolors'
 * own detection, which uses a different precedence.
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
const COLOR_SIGNAL_ENV_KEYS = [
  'APPVEYOR',
  'BUILDKITE',
  'CI',
  'CIRCLECI',
  'CI_NAME',
  'COLORTERM',
  'DRONE',
  'GITHUB_ACTIONS',
  'GITLAB_CI',
  'TEAMCITY_VERSION',
  'TERM',
  'TERM_PROGRAM',
  'TERM_PROGRAM_VERSION',
  'TRAVIS',
];

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
  const originalPlatform = process.platform;

  // Use plain assignment rather than Object.defineProperty: other suites (e.g.
  // index-tty.test.ts) define process.stdout.isTTY as a non-configurable data
  // property, and a later defineProperty would throw "Cannot redefine property".
  // Assignment works whether isTTY is a writable data property or absent.
  function setTTY(isTTY: boolean | undefined): void {
    (process.stdout as { isTTY?: boolean }).isTTY = isTTY;
  }

  function setPlatform(platform: NodeJS.Platform): void {
    Object.defineProperty(process, 'platform', { value: platform, configurable: true });
  }

  beforeEach(() => {
    // Deterministic baseline independent of the runner: clear every signal the
    // color decision keys off, and force a non-TTY stdout. Each test sets only
    // what it is exercising.
    const base = { ...originalEnv };
    delete base.FORCE_COLOR;
    delete base.NO_COLOR;
    for (const key of COLOR_SIGNAL_ENV_KEYS) {
      delete base[key];
    }
    process.env = base;
    setPlatform('linux');
    setTTY(false);
  });

  afterEach(() => {
    process.env = originalEnv;
    setPlatform(originalPlatform);
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

  it('enables color for an interactive TTY with a recognized TERM', () => {
    setTTY(true);
    process.env.TERM = 'xterm-256color';
    expect(colorEnabled()).toBe(true);
  });

  it('disables color for an interactive TTY with unset TERM and no other chalk signal', () => {
    setTTY(true);
    expect(colorEnabled()).toBe(false);
  });

  it('disables color for an interactive TTY with unrecognized TERM and no other chalk signal', () => {
    setTTY(true);
    process.env.TERM = 'acme-terminal';
    expect(colorEnabled()).toBe(false);
  });

  it('enables color for an interactive TTY with COLORTERM despite unrecognized TERM', () => {
    setTTY(true);
    process.env.TERM = 'acme-terminal';
    process.env.COLORTERM = '1';
    expect(colorEnabled()).toBe(true);
  });

  it('disables color for an interactive TTY with TERM=dumb', () => {
    setTTY(true);
    process.env.TERM = 'dumb';
    expect(colorEnabled()).toBe(false);
  });

  it('disables color for a bare CI with non-TTY stdout (chalk-compat override)', () => {
    // picocolors enables color on `!!env.CI` alone; chalk@4 stayed plain unless
    // FORCE_COLOR or a TTY was present. Guards ANSI leaking into captured CI logs.
    process.env.CI = 'true';
    expect(colorEnabled()).toBe(false);
  });

  it('disables color for a generic CI even when stdout is a TTY', () => {
    setTTY(true);
    process.env.CI = 'true';
    process.env.TERM = 'xterm-256color';
    expect(colorEnabled()).toBe(false);
  });

  it('enables color for a recognized CI vendor when stdout is a TTY', () => {
    setTTY(true);
    process.env.CI = 'true';
    process.env.GITHUB_ACTIONS = 'true';
    expect(colorEnabled()).toBe(true);
  });

  it('disables color for Drone CI with no chalk-recognized CI signal', () => {
    setTTY(true);
    process.env.CI = 'true';
    process.env.DRONE = 'true';
    expect(colorEnabled()).toBe(false);
  });

  it('disables color on Windows with non-TTY stdout and no color vars', () => {
    // picocolors enables color for `process.platform === 'win32'` regardless of
    // TTY; chalk@4 required a TTY/FORCE_COLOR first. Guards ANSI escapes in
    // redirected Windows output (e.g. `create-react-on-rails-app app > log.txt`).
    setPlatform('win32');
    expect(colorEnabled()).toBe(false);
  });

  it('enables color on Windows when stdout is a TTY', () => {
    setPlatform('win32');
    setTTY(true);
    expect(colorEnabled()).toBe(true);
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
