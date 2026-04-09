/*
 * React Server Component demo: using react-intl's formatter inside an RSC.
 *
 * ----------------------------------------------------------------------------
 * THE PROBLEM
 * ----------------------------------------------------------------------------
 * React Server Components cannot use React hooks or React Context. This means
 * react-intl's hook-based API — `useIntl()`, `<IntlProvider>`, `<FormattedMessage>` —
 * does NOT work inside a Server Component.
 *
 * But react-intl also exposes a *non-React* API: `createIntl` (re-exported from
 * `@formatjs/intl`). It's a plain JavaScript function that returns an `intl`
 * object with `formatMessage`, `formatNumber`, `formatDate`, etc. — the same
 * methods you'd get from `useIntl()` in a Client Component, minus the Context
 * machinery. That part is safe to call from Server Components.
 *
 * ----------------------------------------------------------------------------
 * THE WORKAROUND: RENDER FUNCTION PATTERN
 * ----------------------------------------------------------------------------
 * To get the current request's locale, we need access to `railsContext` (which
 * carries `i18nLocale` from `I18n.locale` in the Rails controller). React on
 * Rails passes `railsContext` as the second argument to *render functions* —
 * functions with signature `(props, railsContext)` that return a component
 * function. Plain 1-arg Server Components do NOT receive railsContext.
 *
 * `isRenderFunction()` in `packages/react-on-rails/src/isRenderFunction.ts`
 * detects render functions by checking `component.length >= 2`. So writing
 * this Server Component with two parameters is enough for the framework to
 * invoke it with `(props, railsContext)` and serialize the returned element
 * into the RSC Flight payload.
 *
 * ----------------------------------------------------------------------------
 * LIMITATIONS OF THIS WORKAROUND
 * ----------------------------------------------------------------------------
 * 1. Only the REGISTERED top-level Server Component receives `railsContext`.
 *    Nested Server Components still get plain props — you must prop-drill
 *    `intl` or `locale` down the tree.
 * 2. The render function convention is React on Rails specific. It deviates
 *    from the standard React component signature that Next.js / Vite users
 *    are familiar with.
 * 3. Translations are loaded at module scope here to keep the demo simple.
 *    In production you'd generate them via `ReactOnRails::Locales.compile` and
 *    import the generated translations.json.
 *
 * ----------------------------------------------------------------------------
 * THE FUTURE (see shakacode/react_on_rails#3081)
 * ----------------------------------------------------------------------------
 * Once React on Rails ships an AsyncLocalStorage-based request store, any
 * Server Component anywhere in the tree will be able to call a framework-
 * provided helper like `getRailsContext()` or `getTranslations()` WITHOUT
 * being a render function and WITHOUT prop-drilling. At that point this
 * workaround becomes unnecessary.
 *
 * ----------------------------------------------------------------------------
 * SETUP REQUIRED TO RUN THIS DEMO
 * ----------------------------------------------------------------------------
 * 1. Install the non-React core of react-intl in the dummy app:
 *      cd react_on_rails_pro/spec/dummy && pnpm add @formatjs/intl
 * 2. Rebuild the bundles:
 *      pnpm run build:dev
 * 3. Start Rails + node renderer and visit /react_intl_rsc_demo
 *    Use ?locale=en|fr|ar to see the locale change take effect server-side.
 */

import * as React from 'react';
import { createIntl, createIntlCache } from '@formatjs/intl';

// Inline translations keep the demo self-contained. In a real app, these would
// be generated from Rails YAML via `ReactOnRails::Locales.compile` and imported
// from the generated translations.json file.
const MESSAGES = {
  en: {
    'demo.title': 'react-intl inside a React Server Component',
    'demo.localeLabel': 'Current locale (from railsContext.i18nLocale):',
    'demo.greeting': 'Hello, {name}!',
    'demo.itemCount': '{count, plural, one {# item in cart} other {# items in cart}}',
    'demo.price': 'Price: {price, number, ::currency/USD}',
    'demo.today': 'Today is {date, date, long}',
    'demo.relativeTime': 'Posted {value, selectordinal, one {#st} two {#nd} few {#rd} other {#th}} yesterday',
    'demo.description':
      'Everything on this page was rendered by a React Server Component. The component code never ships to the browser; only the formatted text in the Flight payload does.',
  },
  fr: {
    'demo.title': 'react-intl dans un composant serveur React',
    'demo.localeLabel': 'Locale actuelle (depuis railsContext.i18nLocale):',
    'demo.greeting': 'Bonjour, {name} !',
    'demo.itemCount': '{count, plural, one {# article dans le panier} other {# articles dans le panier}}',
    'demo.price': 'Prix : {price, number, ::currency/EUR}',
    'demo.today': "Aujourd'hui est le {date, date, long}",
    'demo.relativeTime': 'Publié {value, selectordinal, one {#er} other {#e}} hier',
    'demo.description':
      "Tout sur cette page a été rendu par un composant serveur React. Le code du composant n'est jamais envoyé au navigateur ; seul le texte formaté dans la charge utile Flight l'est.",
  },
  ar: {
    'demo.title': 'react-intl داخل مكون خادم React',
    'demo.localeLabel': 'اللغة الحالية (من railsContext.i18nLocale):',
    'demo.greeting': 'مرحباً، {name}!',
    'demo.itemCount':
      '{count, plural, zero {لا توجد عناصر في السلة} one {عنصر واحد في السلة} two {عنصران في السلة} few {# عناصر في السلة} many {# عنصراً في السلة} other {# عنصر في السلة}}',
    'demo.price': 'السعر: {price, number, ::currency/USD}',
    'demo.today': 'اليوم هو {date, date, long}',
    'demo.relativeTime': 'نُشر رقم {value} أمس',
    'demo.description':
      'تم عرض كل شيء في هذه الصفحة بواسطة مكون خادم React. لا يتم إرسال كود المكون إلى المتصفح أبداً؛ فقط النص المنسق في حمولة Flight.',
  },
};

// `createIntlCache` is safe to share across requests — it caches *Intl.*Format
// instances (NumberFormat, DateTimeFormat, ...), NOT per-request data. Sharing
// it avoids rebuilding the Intl formatters on every render.
const intlCache = createIntlCache();

/**
 * Render function signature: `(props, railsContext)`.
 *
 * `railsContext.i18nLocale` is set by the Rails controller via `I18n.locale`.
 * The PagesController's `react_intl_rsc_demo` action reads `params[:locale]`
 * and calls `I18n.locale = ...` in a `before_action`, so switching the URL
 * from `?locale=en` to `?locale=fr` changes what this function sees here.
 *
 * React on Rails render functions MUST return a component function (not JSX
 * directly). `createReactOutput` wraps the returned function in
 * `React.createElement(returned, props)` before handing it to React Flight.
 */
const ReactIntlRSCDemo = (props, railsContext) => {
  const locale = railsContext.i18nLocale;
  const messages = MESSAGES[locale] || MESSAGES.en;
  const intl = createIntl({ locale, messages }, intlCache);

  const name = props.userName || 'Abanoub';
  const cartItems = props.cartItems ?? 5;
  const productPrice = props.productPrice ?? 1234.56;
  const now = new Date();

  return function ReactIntlRSCDemoRendered() {
    return (
      <div dir={locale === 'ar' ? 'rtl' : 'ltr'}>
        <h1>{intl.formatMessage({ id: 'demo.title' })}</h1>
        <p>
          <strong>{intl.formatMessage({ id: 'demo.localeLabel' })}</strong> <code>{locale}</code>
        </p>
        <hr />

        <h3>Variable interpolation</h3>
        <p>{intl.formatMessage({ id: 'demo.greeting' }, { name })}</p>

        <h3>Pluralization (ICU MessageFormat)</h3>
        <p>{intl.formatMessage({ id: 'demo.itemCount' }, { count: 0 })}</p>
        <p>{intl.formatMessage({ id: 'demo.itemCount' }, { count: 1 })}</p>
        <p>{intl.formatMessage({ id: 'demo.itemCount' }, { count: 2 })}</p>
        <p>{intl.formatMessage({ id: 'demo.itemCount' }, { count: cartItems })}</p>

        <h3>Number formatting (locale-aware currency)</h3>
        <p>{intl.formatMessage({ id: 'demo.price' }, { price: productPrice })}</p>

        <h3>Date formatting (locale-aware long date)</h3>
        <p>{intl.formatMessage({ id: 'demo.today' }, { date: now })}</p>

        <hr />
        <p>{intl.formatMessage({ id: 'demo.description' })}</p>
      </div>
    );
  };
};

export default ReactIntlRSCDemo;
