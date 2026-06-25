import { resolveSetupMode } from '../src/mode';

describe('resolveSetupMode', () => {
  it('defaults to the recommended Pro setup when no setup mode is given', () => {
    expect(resolveSetupMode({})).toEqual({
      defaulted: true,
      mode: 'rsc',
      pro: false,
      rsc: true,
    });
  });

  it('keeps the standard setup explicit', () => {
    expect(resolveSetupMode({ standard: true })).toEqual({
      defaulted: false,
      mode: 'standard',
      pro: false,
      rsc: false,
    });
  });

  it('keeps Pro SSR explicit', () => {
    expect(resolveSetupMode({ pro: true })).toEqual({
      defaulted: false,
      mode: 'pro',
      pro: true,
      rsc: false,
    });
  });

  it('keeps explicit RSC mode on the recommended Pro setup', () => {
    expect(resolveSetupMode({ rsc: true })).toEqual({
      defaulted: false,
      mode: 'rsc',
      pro: false,
      rsc: true,
    });
  });

  it('keeps --rsc precedence over --pro for compatibility', () => {
    expect(resolveSetupMode({ pro: true, rsc: true })).toEqual({
      defaulted: false,
      mode: 'rsc',
      pro: false,
      rsc: true,
    });
  });

  it('rejects combining --standard with a Pro mode', () => {
    expect(() => resolveSetupMode({ standard: true, pro: true })).toThrow('Choose only one setup mode');
    expect(() => resolveSetupMode({ standard: true, rsc: true })).toThrow('Choose only one setup mode');
  });
});
