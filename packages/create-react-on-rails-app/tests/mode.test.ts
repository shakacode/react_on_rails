import { resolveSetupMode } from '../src/mode';

describe('resolveSetupMode', () => {
  it('defaults to the recommended Pro setup when no setup mode is given', () => {
    expect(resolveSetupMode({})).toEqual({
      defaulted: true,
      mode: 'pro',
      requiresPro: true,
      pro: true,
      rsc: false,
    });
  });

  it('keeps the standard setup explicit', () => {
    expect(resolveSetupMode({ standard: true })).toEqual({
      defaulted: false,
      mode: 'standard',
      requiresPro: false,
      pro: false,
      rsc: false,
    });
  });

  it('keeps Pro SSR explicit', () => {
    expect(resolveSetupMode({ pro: true })).toEqual({
      defaulted: false,
      mode: 'pro',
      requiresPro: true,
      pro: true,
      rsc: false,
    });
  });

  it('keeps explicit RSC mode as a Pro setup option', () => {
    expect(resolveSetupMode({ rsc: true })).toEqual({
      defaulted: false,
      mode: 'rsc',
      requiresPro: true,
      pro: false,
      rsc: true,
    });
  });

  it('rejects combining setup modes', () => {
    expect(() => resolveSetupMode({ standard: true, pro: true })).toThrow('Choose only one setup mode');
    expect(() => resolveSetupMode({ standard: true, rsc: true })).toThrow('Choose only one setup mode');
    expect(() => resolveSetupMode({ pro: true, rsc: true })).toThrow('Choose only one setup mode');
  });
});
