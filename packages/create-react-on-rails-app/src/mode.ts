export type SetupMode = 'standard' | 'pro' | 'rsc';

export interface ResolvedSetupMode {
  defaulted: boolean;
  mode: SetupMode;
  pro: boolean;
  rsc: boolean;
}

export function resolveSetupMode(rawOpts: Record<string, unknown>): ResolvedSetupMode {
  const standard = Boolean(rawOpts.standard);
  const pro = Boolean(rawOpts.pro);
  const rsc = Boolean(rawOpts.rsc);

  if (standard && (pro || rsc)) {
    throw new Error('Choose only one setup mode: --standard, --pro, or --rsc.');
  }

  if (standard) {
    return {
      defaulted: false,
      mode: 'standard',
      pro: false,
      rsc: false,
    };
  }

  if (rsc) {
    return {
      defaulted: false,
      mode: 'rsc',
      pro: false,
      rsc: true,
    };
  }

  if (pro) {
    return {
      defaulted: false,
      mode: 'pro',
      pro: true,
      rsc: false,
    };
  }

  return {
    defaulted: true,
    mode: 'rsc',
    pro: false,
    rsc: true,
  };
}
