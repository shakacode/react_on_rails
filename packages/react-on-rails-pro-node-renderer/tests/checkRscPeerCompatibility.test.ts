import { checkRscPeerCompatibility } from '../src/shared/checkRscPeerCompatibility';

describe('checkRscPeerCompatibility', () => {
  it('returns ok when react-on-rails-rsc is absent (optional peer not installed)', () => {
    expect(checkRscPeerCompatibility({ rscVersion: null, reactVersion: '19.2.0' })).toEqual({ level: 'ok' });
  });

  it('returns ok for a supported stable rsc + react', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.4', reactVersion: '19.2.0' }).level).toBe('ok');
  });

  it('returns ok for a coordinated prerelease (prerelease stripped for comparison)', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.5-rc.6', reactVersion: '19.2.0' }).level).toBe('ok');
  });

  it('returns ok for a version with a leading v (prefix stripped for comparison)', () => {
    expect(checkRscPeerCompatibility({ rscVersion: 'v19.0.4', reactVersion: '19.2.0' }).level).toBe('ok');
  });

  it('errors when rsc major is above the supported major', () => {
    const r = checkRscPeerCompatibility({ rscVersion: '20.0.0', reactVersion: '19.2.0' });
    expect(r.level).toBe('error');
    expect(r.message).toContain('react-on-rails-rsc');
    expect(r.message).toContain('20.0.0');
  });

  it('errors when rsc major is below the supported major', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '18.3.1', reactVersion: '19.2.0' }).level).toBe('error');
  });

  it('errors when React major is below the RSC minimum', () => {
    const r = checkRscPeerCompatibility({ rscVersion: '19.0.4', reactVersion: '18.3.1' });
    expect(r.level).toBe('error');
    expect(r.message).toContain('react');
    expect(r.message).toContain('18.3.1');
    expect(r.message).toContain('>= 19');
  });

  it('warns when rsc is on the supported major but below recommendedMin', () => {
    // recommendedMin is 19.0.2; 19.0.1 is below it.
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.1', reactVersion: '19.2.0' }).level).toBe('warn');
  });

  it('does not warn at exactly recommendedMin', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.2', reactVersion: '19.2.0' }).level).toBe('ok');
  });

  it('skips the React check when React is not resolvable', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.4', reactVersion: null }).level).toBe('ok');
  });
});
