'use client';

import path from 'path';
import React from 'react';
import { ChunkExtractor } from '@loadable/server';
import { renderToString } from 'react-dom/server';
import { Helmet, HelmetProvider } from '@dr.pogodin/react-helmet';

import LeakRepro from '../components/LeakRepro';

const CRITICAL_CSS = `
  .leak-repro { box-sizing: border-box; }
  .leak-repro *, .leak-repro *::before, .leak-repro *::after { box-sizing: inherit; }
  .leak-repro article { transition: box-shadow 0.2s ease, transform 0.2s ease; }
  .leak-repro article:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.12); transform: translateY(-1px); }
  .leak-repro img, .leak-repro svg { max-width: 100%; height: auto; }
  .leak-repro code { font-family: 'JetBrains Mono', 'Fira Code', monospace; }
  .leak-repro p { orphans: 3; widows: 3; }
  .leak-repro h1, .leak-repro h2, .leak-repro h3 { page-break-after: avoid; }
  @media (max-width: 768px) {
    .leak-repro article { padding: 12px 16px !important; }
    .leak-repro [style*="grid-template-columns"] { grid-template-columns: 1fr !important; }
  }
  @media (max-width: 480px) {
    .leak-repro article { margin: 8px 0 !important; }
    .leak-repro header { padding: 16px !important; }
  }
  @media (prefers-reduced-motion: reduce) {
    .leak-repro article { transition: none !important; }
    .leak-repro article:hover { transform: none !important; }
  }
  @media print {
    .leak-repro { max-width: 100% !important; padding: 0 !important; }
    .leak-repro article { break-inside: avoid; box-shadow: none !important; border: 1px solid #ccc !important; }
    .leak-repro header { background: #fff !important; color: #000 !important; }
  }
`;

const LeakReproHashApp = (props, _railsContext) => {
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');
  const extractor = new ChunkExtractor({ entrypoints: ['client-bundle'], statsFile });
  const helmetContext = {};
  const itemCount = props.items ? props.items.length : 0;
  const componentHtml = renderToString(
    extractor.collectChunks(
      <HelmetProvider context={helmetContext}>
        <Helmet>
          <title>
            Leak Repro — {itemCount} Items | {props.siteConfig?.name || 'Benchmark'}
          </title>
          <meta
            name="description"
            content={`Server-rendered page with ${itemCount} items for memory leak measurement. Generated at ${props.generatedAt}.`}
          />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta property="og:title" content={`Leak Repro — ${itemCount} Items`} />
          <meta
            property="og:description"
            content={`Benchmark page rendering ${itemCount} complex items with nested comments, SVG thumbnails, and metadata panels.`}
          />
          <meta property="og:type" content="website" />
          <meta property="og:image" content="https://placeholders.example.com/og-1200x630.png" />
          <meta name="twitter:card" content="summary_large_image" />
          <meta name="twitter:title" content={`Leak Repro — ${itemCount} Items`} />
          <meta name="robots" content="noindex, nofollow" />
          <meta name="theme-color" content={props.siteConfig?.theme?.primary || '#1a73e8'} />
          <meta name="generator" content={`LeakRepro v${props.siteConfig?.version || '2.0'}`} />
          <link rel="preconnect" href="https://fonts.googleapis.com" />
          <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
          <link rel="dns-prefetch" href="https://placeholders.example.com" />
          <link rel="canonical" href="https://example.com/leak-repro" />
          <style type="text/css">{CRITICAL_CSS}</style>
        </Helmet>
        <LeakRepro {...props} />
      </HelmetProvider>,
    ),
  );
  const { helmet } = helmetContext;

  return {
    renderedHtml: {
      componentHtml,
      link: helmet?.link?.toString() || '',
      linkTags: extractor.getLinkTags(),
      styleTags: extractor.getStyleTags(),
      meta: helmet?.meta?.toString() || '',
      scriptTags: extractor.getScriptTags(),
      style: helmet?.style?.toString() || '',
      title: helmet?.title?.toString() || '',
    },
  };
};

export default LeakReproHashApp;
