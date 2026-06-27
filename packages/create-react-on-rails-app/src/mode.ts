export type SetupMode = 'standard' | 'pro' | 'rsc';

interface ResolvedSetupModeBase {
  defaulted: boolean;
  mode: SetupMode;
}

interface StandardResolvedSetupMode extends ResolvedSetupModeBase {
  defaulted: false;
  mode: 'standard';
  requiresPro: false;
  pro: false;
  rsc: false;
}

interface ProResolvedSetupMode extends ResolvedSetupModeBase {
  mode: 'pro';
  /** True when the selected setup installs react_on_rails_pro. */
  requiresPro: true;
  /** True for the Pro-without-RSC generator path. RSC mode uses its own Pro path. */
  pro: true;
  rsc: false;
}

interface RscResolvedSetupMode extends ResolvedSetupModeBase {
  defaulted: false;
  mode: 'rsc';
  /** True when the selected setup installs react_on_rails_pro. */
  requiresPro: true;
  /** RSC mode uses its own Pro generator path, so this generator flag is false. */
  pro: false;
  rsc: true;
}

export type ResolvedSetupMode = StandardResolvedSetupMode | ProResolvedSetupMode | RscResolvedSetupMode;

function makeSetupMode(mode: SetupMode, defaulted: boolean): ResolvedSetupMode {
  if (mode === 'standard') {
    return {
      defaulted: false,
      mode,
      requiresPro: false,
      pro: false,
      rsc: false,
    };
  }

  if (mode === 'rsc') {
    return {
      defaulted: false,
      mode,
      requiresPro: true,
      pro: false,
      rsc: true,
    };
  }

  return {
    defaulted,
    mode,
    requiresPro: true,
    pro: true,
    rsc: false,
  };
}

export function resolveSetupMode(rawOpts: Record<string, unknown>): ResolvedSetupMode {
  const standard = Boolean(rawOpts.standard);
  const pro = Boolean(rawOpts.pro);
  const rsc = Boolean(rawOpts.rsc);

  if ([standard, pro, rsc].filter(Boolean).length > 1) {
    throw new Error('Choose only one setup mode: --standard, --pro, or --rsc.');
  }

  if (standard) {
    return makeSetupMode('standard', false);
  }

  if (rsc) {
    return makeSetupMode('rsc', false);
  }

  if (pro) {
    return makeSetupMode('pro', false);
  }

  return makeSetupMode('pro', true);
}
