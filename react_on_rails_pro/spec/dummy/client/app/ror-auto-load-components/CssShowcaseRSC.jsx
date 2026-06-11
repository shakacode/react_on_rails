import React from 'react';
import ServerCssModulesProbe from '../components/CssShowcase/ServerCssModulesProbe';
import ServerTailwindProbe from '../components/CssShowcase/ServerTailwindProbe';
import ServerInlineStylesProbe from '../components/CssShowcase/ServerInlineStylesProbe';
import PlainCssProbe from '../components/CssShowcase/PlainCssProbe';
import CssModulesProbe from '../components/CssShowcase/CssModulesProbe';
import ScssModulesProbe from '../components/CssShowcase/ScssModulesProbe';
import TailwindProbe from '../components/CssShowcase/TailwindProbe';
import InlineStylesProbe from '../components/CssShowcase/InlineStylesProbe';
import StyledComponentsProbe from '../components/CssShowcase/StyledComponentsProbe';
import EmotionProbe from '../components/CssShowcase/EmotionProbe';

const CssShowcaseRSC = () => (
  <div data-testid="css-showcase-rsc">
    <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>
      CSS Showcase — React Server Components
    </h2>

    <h3 style={{ fontSize: '1.2rem', fontWeight: '600', margin: '1rem 0 0.5rem' }}>
      Server Components (no &apos;use client&apos;)
    </h3>
    <p style={{ marginBottom: '0.5rem', color: '#666' }}>
      These components run on the server. Only build-time CSS approaches work here.
    </p>
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
      <ServerCssModulesProbe />
      <ServerTailwindProbe />
      <ServerInlineStylesProbe />
    </div>

    <h3 style={{ fontSize: '1.2rem', fontWeight: '600', margin: '1rem 0 0.5rem' }}>
      Client Components (&apos;use client&apos;) in RSC Tree
    </h3>
    <p style={{ marginBottom: '0.5rem', color: '#666' }}>
      These components have the &apos;use client&apos; directive. All CSS approaches work here.
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

export default CssShowcaseRSC;
