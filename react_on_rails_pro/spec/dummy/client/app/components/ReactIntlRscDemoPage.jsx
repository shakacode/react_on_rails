'use client';

import React, { useState, useCallback, Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

const LOCALES = [
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'ar', label: 'العربية', flag: '🇸🇦' },
  { code: 'es', label: 'Español', flag: '🇪🇸' },
];

const VALID_LOCALE_CODES = new Set(LOCALES.map(l => l.code));
const BASE_PATH = '/react_intl_rsc_demo';

const ReactIntlRscDemoPage = ({ locale: initialLocale }) => {
  const safeInitial = VALID_LOCALE_CODES.has(initialLocale) ? initialLocale : 'en';
  const [locale, setLocale] = useState(safeInitial);

  const handleLocaleChange = useCallback((code) => {
    setLocale(code);
    const newPath = code === 'en' ? BASE_PATH : `${BASE_PATH}/${code}`;
    window.history.replaceState(null, '', newPath);
  }, []);

  return (
    <div style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 700, margin: '0 auto', padding: 20 }}>
      <div style={{
        display: 'flex',
        gap: 8,
        marginBottom: 24,
        padding: 16,
        background: '#f0f9ff',
        borderRadius: 8,
        border: '1px solid #bae6fd',
        alignItems: 'center',
      }}>
        <span style={{ fontWeight: 'bold', marginRight: 8 }}>Language:</span>
        {LOCALES.map(({ code, label, flag }) => (
          <button
            key={code}
            onClick={() => handleLocaleChange(code)}
            style={{
              padding: '8px 16px',
              borderRadius: 6,
              border: locale === code ? '2px solid #2563eb' : '1px solid #d1d5db',
              background: locale === code ? '#2563eb' : 'white',
              color: locale === code ? 'white' : '#374151',
              cursor: 'pointer',
              fontSize: 14,
              fontWeight: locale === code ? 'bold' : 'normal',
            }}
          >
            {flag} {label}
          </button>
        ))}
      </div>

      <Suspense
        fallback={
          <div style={{ padding: 40, textAlign: 'center', color: '#9ca3af' }}>
            Loading server component for locale "{locale}"...
          </div>
        }
      >
        <RSCRoute
          componentName="ReactIntlRscDemo"
          componentProps={{ locale }}
          ssr={true}
        />
      </Suspense>
    </div>
  );
};

export default ReactIntlRscDemoPage;
