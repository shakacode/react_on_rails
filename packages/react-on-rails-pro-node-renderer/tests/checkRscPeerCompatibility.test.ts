import { checkRscPeerCompatibility } from '../src/shared/checkRscPeerCompatibility';
import { RSC_PEER_SUPPORT } from '../src/shared/rscPeerSupport';

const { recommendedMin } = RSC_PEER_SUPPORT.reactOnRailsRsc;

const versionBelowRecommendedMin = (version: string) => {
  const [major, minor, patch] = version.split('.').map(Number);
  if (patch > 0) return `${major}.${minor}.${patch - 1}`;
  if (minor > 0) return `${major}.${minor - 1}.999`;
  throw new Error('recommendedMin must allow a lower supported-major version for the warn-tier test');
};

const belowRecommendedMin = versionBelowRecommendedMin(recommendedMin);

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
    expect(checkRscPeerCompatibility({ rscVersion: belowRecommendedMin, reactVersion: '19.2.0' }).level).toBe(
      'warn',
    );
  });

  it('does not warn at exactly recommendedMin', () => {
    expect(checkRscPeerCompatibility({ rscVersion: recommendedMin, reactVersion: '19.2.0' }).level).toBe(
      'ok',
    );
  });

  it('skips the React check when React is not resolvable', () => {
    expect(checkRscPeerCompatibility({ rscVersion: '19.0.4', reactVersion: null }).level).toBe('ok');
  });
});
