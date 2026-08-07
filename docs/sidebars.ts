import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

// Intentionally excluded from sidebar (legacy stubs that redirect to archive):
// - building-features/hmr-and-hot-reloading-with-the-webpack-dev-server
// - building-features/rails-webpacker-react-integration-options
// - deployment/troubleshooting-when-using-webpacker
// - misc/asset-pipeline
//
// URL-compatibility stubs (redirect to a current, live page):
// - pro/home-pro (→ pro/react-on-rails-pro)
//
// Contributing/Resources pages (linked from introduction.md instead of sidebar):
// - misc/doctrine
// - misc/style
// - misc/updating-dependencies
// - misc/credits
// - misc/articles
// - misc/tips

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'introduction',
    {
      type: 'category',
      label: 'Getting Started',
      link: { type: 'generated-index', title: 'Getting Started' },
      collapsed: false,
      items: [
        'getting-started/quick-start',
        'getting-started/examples-and-references',
        'getting-started/create-react-on-rails-app',
        'getting-started/tutorial',
        'getting-started/installation-into-an-existing-rails-app',
        'getting-started/consuming-an-unreleased-build',
        'getting-started/project-structure',
        'getting-started/using-react-on-rails',
        'getting-started/oss-vs-pro',
        'getting-started/pro-quick-start',
        'getting-started/comparing-react-on-rails-to-alternatives',
        'getting-started/why-rspack',
        'getting-started/common-issues',
      ],
    },
    {
      type: 'category',
      label: 'Core Concepts',
      link: { type: 'generated-index', title: 'Core Concepts' },
      items: [
        'core-concepts/how-react-on-rails-works',
        'core-concepts/client-vs-server-rendering',
        'core-concepts/react-server-rendering',
        'core-concepts/render-functions-and-railscontext',
        'core-concepts/render-functions',
        'core-concepts/auto-bundling-file-system-based-automated-bundle-generation',
        'core-concepts/webpack-configuration',
        'core-concepts/execjs-limitations',
        'core-concepts/performance-benchmarks',
      ],
    },
    {
      type: 'category',
      label: 'Building Features',
      link: { type: 'generated-index', title: 'Building Features' },
      items: [
        {
          type: 'category',
          label: 'Routing',
          items: [
            'building-features/react-router',
            'building-features/tanstack-router',
            'building-features/client-side-routing-instant-navigation',
          ],
        },
        {
          type: 'category',
          label: 'Rendering',
          items: [
            'building-features/code-splitting',
            'building-features/hydration-scheduling',
            'building-features/react-helmet',
            'building-features/react-19-native-metadata',
            'building-features/react-19-activity',
            'building-features/react-compiler',
            'building-features/view-transitions',
            'building-features/streaming-server-rendering',
            'building-features/how-to-conditionally-server-render-based-on-device-type',
            'building-features/how-to-use-different-files-for-client-and-server-rendering',
            'building-features/caching',
            'building-features/bundle-caching',
          ],
        },
        {
          type: 'category',
          label: 'Integrations',
          items: [
            'building-features/accessibility',
            'building-features/forms',
            'building-features/mutations',
            'building-features/react-and-redux',
            'building-features/tanstack-query',
            'building-features/generated-rails-response-types',
            'building-features/styling-with-tailwind',
            'building-features/i18n',
            'building-features/images',
            'building-features/fast-images',
            'building-features/fonts',
            'building-features/rails-engine-integration',
            'building-features/web-components',
            'building-features/turbolinks',
          ],
        },
        {
          type: 'category',
          label: 'Development & Ops',
          items: [
            'building-features/dev-server-and-testing',
            'building-features/testing-configuration',
            'building-features/extensible-precompile-pattern',
            'building-features/process-managers',
            'building-features/debugging',
            'building-features/debugging-hydration-mismatches',
            'building-features/performance-tracks-and-profiling',
            'building-features/web-vitals-and-rum',
          ],
        },
        {
          type: 'category',
          label: 'Node Renderer (Pro)',
          items: [
            'building-features/node-renderer/basics',
            'building-features/node-renderer/js-configuration',
            'building-features/node-renderer/container-deployment',
            'building-features/node-renderer/health-checks',
            'building-features/node-renderer/debugging',
            'building-features/node-renderer/error-reporting-and-tracing',
            'building-features/node-renderer/heroku',
            'building-features/node-renderer/troubleshooting',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      link: { type: 'generated-index', title: 'Reference' },
      items: [
        'reference/error-reference',
        {
          type: 'category',
          label: 'Configuration',
          items: [
            'configuration/README',
            'configuration/configuration-pro',
            'configuration/configuration-deprecated',
          ],
        },
        {
          type: 'category',
          label: 'APIs',
          items: [
            'api-reference/view-helpers-api',
            'api-reference/javascript-api',
            'api-reference/redux-store-api',
            'api-reference/ruby-api-pro',
            'api-reference/generator-details',
            'api-reference/doctor',
            'api-reference/rails-view-rendering-from-inline-javascript',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'Deployment',
      link: { type: 'doc', id: 'deployment/README' },
      items: [
        'deployment/docker-deployment',
        'deployment/heroku-deployment',
        'deployment/review-app-security',
        'deployment/security-model-and-hardening',
        'deployment/server-rendering-tips',
        'deployment/troubleshooting',
        'deployment/troubleshooting-build-errors',
        'deployment/troubleshooting-when-using-shakapacker',
      ],
    },
    {
      type: 'category',
      label: 'Upgrading & Migration',
      link: { type: 'generated-index', title: 'Upgrading & Migration' },
      items: [
        'upgrading/upgrading-react-on-rails',
        'upgrading/release-notes/index',
        'pro/updating',
        'pro/major-performance-breakthroughs-upgrade-guide',
        'pro/release-notes/index',
        {
          type: 'link',
          label: 'Full Changelog',
          href: 'https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md',
        },
        {
          type: 'category',
          label: 'Migration Guides',
          items: [
            'migrating/example-migrations',
            'migrating/migrating-from-nextjs',
            'migrating/migrating-from-react-rails',
            'migrating/migrating-from-inertia-rails',
            'migrating/migrating-from-vite-rails',
            'migrating/migrating-from-webpack-to-rspack',
            'migrating/babel-to-swc-migration',
            'migrating/convert-rails-5-api-only-app',
            'migrating/angular-js-integration-migration',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: 'React on Rails Pro',
      link: { type: 'doc', id: 'pro/react-on-rails-pro' },
      items: [
        'pro/installation',
        'pro/license-ci-integration',
        'pro/deployment/review-app-security',
        'pro/upgrading-to-pro',
        'pro/streaming-ssr',
        'pro/strict-csp',
        'pro/async-props-database-queries',
        'pro/node-renderer',
        'pro/rolling-deploy-adapters',
        'pro/rolling-deploy-custom-adapters',
        'pro/fragment-caching',
        'pro/js-memory-leaks',
        'pro/profiling-server-side-rendering-code',
        'pro/troubleshooting',
        {
          type: 'category',
          label: 'React Server Components',
          link: { type: 'doc', id: 'pro/react-server-components/index' },
          items: [
            'pro/react-server-components/purpose-and-benefits',
            'pro/react-server-components/success-stories',
            'pro/react-server-components/how-react-server-components-work',
            'pro/react-server-components/rendering-flow',
            'pro/react-server-components/critical-resource-hints',
            'pro/react-server-components/css-and-styling',
            'pro/react-server-components/static-shell-global-js-opt-out',
            'pro/react-server-components/tutorial',
            'pro/react-server-components/server-side-rendering',
            'pro/react-server-components/add-streaming-and-interactivity',
            'pro/react-server-components/create-without-ssr',
            'pro/react-server-components/inside-client-components',
            'pro/react-server-components/selective-hydration-in-streamed-components',
            'pro/react-server-components/client-reference-diagnostics',
            'pro/react-server-components/system-spec-streaming-rsc',
            'pro/react-server-components/flight-protocol-syntax',
            'pro/react-server-components/upgrading-existing-pro-app',
            'pro/react-server-components/per-request-data',
            'pro/react-server-components/rspack-compatibility',
            'pro/react-server-components/nextjs-comparison',
            'pro/react-server-components/tanstack-start-comparison',
            'pro/react-server-components/glossary',
            {
              type: 'category',
              label: 'Migrating to RSC',
              items: [
                'migrating/migrating-to-rsc',
                'migrating/rsc-preparing-app',
                'migrating/rsc-component-patterns',
                'migrating/rsc-context-and-state',
                'migrating/rsc-data-fetching',
                'migrating/rsc-http-response-patterns',
                'migrating/rsc-third-party-libs',
                'migrating/rsc-troubleshooting',
                'migrating/rsc-flight-payload',
                'migrating/rsc-performance-validation',
                'migrating/rsc-static-shell-sidecar',
              ],
            },
          ],
        },
      ],
    },
  ],
};

export default sidebars;
