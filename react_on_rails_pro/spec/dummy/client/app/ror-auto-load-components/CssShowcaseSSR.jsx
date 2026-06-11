import React from 'react';
import PlainCssProbe from '../components/CssShowcase/PlainCssProbe';
import CssModulesProbe from '../components/CssShowcase/CssModulesProbe';
import ScssModulesProbe from '../components/CssShowcase/ScssModulesProbe';
import TailwindProbe from '../components/CssShowcase/TailwindProbe';
import InlineStylesProbe from '../components/CssShowcase/InlineStylesProbe';
import StyledComponentsProbe from '../components/CssShowcase/StyledComponentsProbe';
import EmotionProbe from '../components/CssShowcase/EmotionProbe';

const CssShowcaseSSR = () => (
  <div data-testid="css-showcase-ssr">
    <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>
      CSS Showcase — Traditional SSR
    </h2>
    <p style={{ marginBottom: '0.5rem', color: '#666' }}>
      All components rendered with <code>prerender: true</code> (server-side rendering + client hydration)
    </p>
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
      <PlainCssProbe />
      <CssModulesProbe />
      <ScssModulesProbe />
      <TailwindProbe />
      <InlineStylesProbe />
      <StyledComponentsProbe />
      <EmotionProbe />
    </div>
  </div>
);

export default CssShowcaseSSR;
