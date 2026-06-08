import React from 'react';
import getIntl from '../i18n/getIntl';

const SECTION = {
  marginBottom: 32,
  padding: 20,
  background: '#fff',
  borderRadius: 12,
  border: '1px solid #e5e7eb',
};
const SECTION_TITLE = {
  fontSize: 18,
  fontWeight: 700,
  marginBottom: 16,
  paddingBottom: 8,
  borderBottom: '2px solid #2563eb',
  color: '#1e3a5f',
};
const GRID2 = { display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 };
const GRID3 = { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 };
const CELL = { background: '#f8fafc', borderRadius: 8, padding: 14 };
const LABEL = {
  fontSize: 11,
  color: '#6b7280',
  textTransform: 'uppercase',
  letterSpacing: '0.05em',
  marginBottom: 4,
};
const VALUE = { fontSize: 15, fontWeight: 500, color: '#111827' };
const BADGE = (bg, color) => ({
  display: 'inline-block',
  padding: '2px 8px',
  borderRadius: 999,
  fontSize: 11,
  fontWeight: 600,
  background: bg,
  color,
  marginLeft: 8,
});

function GreetingSection({ locale }) {
  const intl = getIntl(locale);
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.greeting' })}</div>
      <p style={{ fontSize: 20, lineHeight: 1.5 }}>{intl.formatMessage({ id: 'greeting' })}</p>
    </div>
  );
}

function StatsSection({ locale }) {
  const intl = getIntl(locale);
  const stats = [
    { label: intl.formatMessage({ id: 'stats.visitors' }, { count: 1234 }), icon: '👥' },
    { label: intl.formatMessage({ id: 'stats.orders' }, { count: 42 }), icon: '📦' },
    { label: `${intl.formatMessage({ id: 'stats.rating' }, { rating: 4.8 })} ⭐`, icon: '' },
    {
      label: `${intl.formatMessage({ id: 'stats.revenue' })}: ${intl.formatNumber(128750.5, { style: 'currency', currency: 'USD' })}`,
      icon: '💰',
    },
    {
      label: `${intl.formatMessage({ id: 'stats.conversion' })}: ${intl.formatNumber(0.0342, { style: 'percent', minimumFractionDigits: 1 })}`,
      icon: '📈',
    },
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.stats' })}</div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 12 }}>
        {stats.map((s, i) => (
          <div key={i} style={{ ...CELL, textAlign: 'center' }}>
            {s.icon && <div style={{ fontSize: 24, marginBottom: 4 }}>{s.icon}</div>}
            <span style={{ fontSize: 14 }}>{s.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ProductCard({ locale, nameKey, descKey, price, stock, badgeKey, badgeColor }) {
  const intl = getIntl(locale);
  return (
    <div style={{ border: '1px solid #e5e7eb', borderRadius: 8, padding: 16, marginBottom: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <h3 style={{ margin: 0 }}>
          {intl.formatMessage({ id: nameKey })}
          <span style={BADGE(badgeColor[0], badgeColor[1])}>{intl.formatMessage({ id: badgeKey })}</span>
        </h3>
      </div>
      <p style={{ color: '#666', margin: '8px 0' }}>{intl.formatMessage({ id: descKey })}</p>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <strong style={{ fontSize: 20, color: '#2563eb' }}>
          {intl.formatMessage(
            { id: 'product.price' },
            { price: intl.formatNumber(price, { style: 'currency', currency: 'USD' }) },
          )}
        </strong>
        <span style={{ fontSize: 13, color: '#6b7280' }}>
          {intl.formatMessage({ id: 'product.stock' }, { count: stock })}
        </span>
      </div>
    </div>
  );
}

function ProductsSection({ locale }) {
  const intl = getIntl(locale);
  const products = [
    {
      nameKey: 'product.widget.name',
      descKey: 'product.widget.description',
      price: 29.99,
      stock: 156,
      badgeKey: 'product.badge.popular',
      badgeColor: ['#fef3c7', '#92400e'],
    },
    {
      nameKey: 'product.gadget.name',
      descKey: 'product.gadget.description',
      price: 49.99,
      stock: 1,
      badgeKey: 'product.badge.new',
      badgeColor: ['#d1fae5', '#065f46'],
    },
    {
      nameKey: 'product.sensor.name',
      descKey: 'product.sensor.description',
      price: 199.99,
      stock: 23,
      badgeKey: 'product.badge.sale',
      badgeColor: ['#fee2e2', '#991b1b'],
    },
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.products' })}</div>
      {products.map((p, i) => (
        <ProductCard key={i} locale={locale} {...p} />
      ))}
    </div>
  );
}

function DatesSection({ locale }) {
  const intl = getIntl(locale);
  const now = new Date(2026, 5, 5, 14, 30, 0);
  const eventEnd = new Date(2026, 5, 12, 18, 0, 0);
  const rows = [
    [intl.formatMessage({ id: 'dates.short' }), intl.formatDate(now, { dateStyle: 'short' })],
    [intl.formatMessage({ id: 'dates.long' }), intl.formatDate(now, { dateStyle: 'long' })],
    [intl.formatMessage({ id: 'dates.full' }), intl.formatDate(now, { dateStyle: 'full' })],
    [intl.formatMessage({ id: 'dates.timeOnly' }), intl.formatTime(now, { timeStyle: 'medium' })],
    [intl.formatMessage({ id: 'dates.weekday' }), intl.formatDate(now, { weekday: 'long' })],
    [intl.formatMessage({ id: 'dates.era' }), intl.formatDate(now, { year: 'numeric', era: 'long' })],
    [
      intl.formatMessage({ id: 'dates.eventStart' }),
      intl.formatDate(now, { dateStyle: 'medium', timeStyle: 'short' }),
    ],
    [
      intl.formatMessage({ id: 'dates.eventEnd' }),
      intl.formatDate(eventEnd, { dateStyle: 'medium', timeStyle: 'short' }),
    ],
    [
      intl.formatMessage({ id: 'dates.dateRange' }),
      intl.formatDateTimeRange(now, eventEnd, { dateStyle: 'medium' }),
    ],
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.dates' })}</div>
      <div style={GRID2}>
        {rows.map(([label, value], i) => (
          <div key={i} style={CELL}>
            <div style={LABEL}>{label}</div>
            <div style={VALUE}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function RelativeTimeSection({ locale }) {
  const intl = getIntl(locale);
  const items = [
    [
      intl.formatMessage({ id: 'relative.justNow' }),
      intl.formatRelativeTime(-3, 'second', { numeric: 'auto' }),
    ],
    [intl.formatMessage({ id: 'relative.minutesAgo' }), intl.formatRelativeTime(-12, 'minute')],
    [intl.formatMessage({ id: 'relative.hoursAgo' }), intl.formatRelativeTime(-5, 'hour')],
    [intl.formatMessage({ id: 'relative.daysAgo' }), intl.formatRelativeTime(-30, 'day')],
    [intl.formatMessage({ id: 'relative.monthsAgo' }), intl.formatRelativeTime(-4, 'month')],
    [intl.formatMessage({ id: 'relative.inFuture' }), intl.formatRelativeTime(14, 'day')],
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.relative' })}</div>
      <div style={GRID3}>
        {items.map(([label, value], i) => (
          <div key={i} style={CELL}>
            <div style={LABEL}>{label}</div>
            <div style={VALUE}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function NumbersSection({ locale }) {
  const intl = getIntl(locale);
  const rows = [
    [intl.formatMessage({ id: 'numbers.integer' }), intl.formatNumber(8425000)],
    [
      intl.formatMessage({ id: 'numbers.decimal' }),
      intl.formatNumber(3.14159265, { maximumFractionDigits: 6 }),
    ],
    [intl.formatMessage({ id: 'numbers.percent' }), intl.formatNumber(0.87, { style: 'percent' })],
    [
      intl.formatMessage({ id: 'numbers.currency' }),
      intl.formatNumber(12500.75, { style: 'currency', currency: 'USD' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.currencyAccounting' }),
      intl.formatNumber(-3200, { style: 'currency', currency: 'USD', currencySign: 'accounting' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.compact' }),
      intl.formatNumber(8000000000, { notation: 'compact', compactDisplay: 'long' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.scientific' }),
      intl.formatNumber(299792458, { notation: 'scientific' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.unit.speed' }),
      intl.formatNumber(25.4, { style: 'unit', unit: 'kilometer-per-hour', unitDisplay: 'long' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.unit.temp' }),
      intl.formatNumber(22.5, { style: 'unit', unit: 'celsius' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.unit.data' }),
      intl.formatNumber(1.54, { style: 'unit', unit: 'gigabyte', unitDisplay: 'long' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.unit.weight' }),
      intl.formatNumber(2.3, { style: 'unit', unit: 'kilogram', unitDisplay: 'long' }),
    ],
    [
      intl.formatMessage({ id: 'numbers.signDisplay' }),
      intl.formatNumber(2.47, { style: 'percent', signDisplay: 'always' }),
    ],
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.numbers' })}</div>
      <div style={GRID3}>
        {rows.map(([label, value], i) => (
          <div key={i} style={CELL}>
            <div style={LABEL}>{label}</div>
            <div style={{ ...VALUE, fontFamily: 'monospace' }}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function ListsSection({ locale }) {
  const intl = getIntl(locale);
  const colors = ['lists.color.red', 'lists.color.blue', 'lists.color.green', 'lists.color.black'].map((id) =>
    intl.formatMessage({ id }),
  );
  const payments = ['lists.pay.card', 'lists.pay.paypal', 'lists.pay.crypto'].map((id) =>
    intl.formatMessage({ id }),
  );
  const features = ['lists.feat.fast', 'lists.feat.secure', 'lists.feat.support', 'lists.feat.api'].map(
    (id) => intl.formatMessage({ id }),
  );
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.lists' })}</div>
      <div style={GRID3}>
        <div style={CELL}>
          <div style={LABEL}>{intl.formatMessage({ id: 'lists.conjunction' })} (and)</div>
          <div style={VALUE}>{intl.formatList(colors, { type: 'conjunction' })}</div>
        </div>
        <div style={CELL}>
          <div style={LABEL}>{intl.formatMessage({ id: 'lists.disjunction' })} (or)</div>
          <div style={VALUE}>{intl.formatList(payments, { type: 'disjunction' })}</div>
        </div>
        <div style={CELL}>
          <div style={LABEL}>{intl.formatMessage({ id: 'lists.features' })} (unit)</div>
          <div style={VALUE}>{intl.formatList(features, { type: 'unit' })}</div>
        </div>
      </div>
    </div>
  );
}

function DisplayNamesSection({ locale }) {
  const intl = getIntl(locale);
  const rows = [
    [
      intl.formatMessage({ id: 'display.selfLanguage' }),
      intl.formatDisplayName(locale, { type: 'language' }),
    ],
    [
      intl.formatMessage({ id: 'display.language' }) + ' (en)',
      intl.formatDisplayName('en', { type: 'language' }),
    ],
    [
      intl.formatMessage({ id: 'display.language' }) + ' (ja)',
      intl.formatDisplayName('ja', { type: 'language' }),
    ],
    [
      intl.formatMessage({ id: 'display.language' }) + ' (zh)',
      intl.formatDisplayName('zh', { type: 'language' }),
    ],
    [
      intl.formatMessage({ id: 'display.region' }) + ' (US)',
      intl.formatDisplayName('US', { type: 'region' }),
    ],
    [
      intl.formatMessage({ id: 'display.region' }) + ' (JP)',
      intl.formatDisplayName('JP', { type: 'region' }),
    ],
    [
      intl.formatMessage({ id: 'display.region' }) + ' (SA)',
      intl.formatDisplayName('SA', { type: 'region' }),
    ],
    [
      intl.formatMessage({ id: 'display.currency' }) + ' (EUR)',
      intl.formatDisplayName('EUR', { type: 'currency' }),
    ],
    [
      intl.formatMessage({ id: 'display.currency' }) + ' (JPY)',
      intl.formatDisplayName('JPY', { type: 'currency' }),
    ],
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.displayNames' })}</div>
      <div style={GRID3}>
        {rows.map(([label, value], i) => (
          <div key={i} style={CELL}>
            <div style={LABEL}>{label}</div>
            <div style={VALUE}>{value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function AdvancedICUSection({ locale }) {
  const intl = getIntl(locale);
  const examples = [
    {
      label: 'select + plural (male)',
      value: intl.formatMessage({ id: 'advanced.gender' }, { gender: 'male', count: 3 }),
    },
    {
      label: 'select + plural (female)',
      value: intl.formatMessage({ id: 'advanced.gender' }, { gender: 'female', count: 1 }),
    },
    {
      label: 'select + plural (other)',
      value: intl.formatMessage({ id: 'advanced.gender' }, { gender: 'other', count: 7 }),
    },
    {
      label: 'selectordinal (1st)',
      value: intl.formatMessage({ id: 'advanced.ordinal' }, { place: 1 }),
    },
    {
      label: 'selectordinal (2nd)',
      value: intl.formatMessage({ id: 'advanced.ordinal' }, { place: 2 }),
    },
    {
      label: 'selectordinal (23rd)',
      value: intl.formatMessage({ id: 'advanced.ordinal' }, { place: 23 }),
    },
    {
      label: 'nested plural (1 host)',
      value: intl.formatMessage({ id: 'advanced.nested' }, { host: 'Alice', hostCount: 1, otherCount: 0 }),
    },
    {
      label: 'nested plural (3 hosts)',
      value: intl.formatMessage({ id: 'advanced.nested' }, { host: 'Alice', hostCount: 3, otherCount: 2 }),
    },
    {
      label: 'rich text',
      value: intl.formatMessage(
        { id: 'advanced.richText' },
        {
          link: (chunks) => `[${chunks}]`,
          bold: (chunks) => `**${chunks}**`,
        },
      ),
    },
    {
      label: 'escaped apostrophes',
      value: intl.formatMessage({ id: 'advanced.escape' }, { percent: '30%' }),
    },
  ];
  return (
    <div style={SECTION}>
      <div style={SECTION_TITLE}>{intl.formatMessage({ id: 'page.section.advanced' })}</div>
      <div style={GRID2}>
        {examples.map((ex, i) => (
          <div key={i} style={CELL}>
            <div style={LABEL}>{ex.label}</div>
            <div style={VALUE}>{ex.value}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Footer({ locale, componentCount }) {
  const intl = getIntl(locale);
  return (
    <footer
      style={{
        marginTop: 32,
        padding: 20,
        background: '#1f2937',
        color: '#9ca3af',
        borderRadius: 12,
        fontSize: 13,
      }}
    >
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 24 }}>
        <span>
          {intl.formatMessage(
            { id: 'footer.rendered_at' },
            { time: intl.formatTime(new Date(), { timeStyle: 'medium' }) },
          )}
        </span>
        <span>{intl.formatMessage({ id: 'footer.locale' }, { locale })}</span>
        <span>{intl.formatMessage({ id: 'footer.components' }, { count: componentCount })}</span>
      </div>
      <p style={{ fontStyle: 'italic', color: '#6b7280', marginTop: 8, marginBottom: 0 }}>
        {intl.formatMessage({ id: 'footer.cache_note' })}
      </p>
    </footer>
  );
}

const COMPONENT_COUNT = 14;

const ReactIntlRscDemo = ({ locale = 'en' }) => {
  const intl = getIntl(locale);
  const dir = locale === 'ar' ? 'rtl' : 'ltr';
  return (
    <div
      dir={dir}
      style={{
        fontFamily: 'system-ui, sans-serif',
        maxWidth: 800,
        margin: '0 auto',
        padding: 20,
        background: '#f3f4f6',
        minHeight: '100vh',
      }}
    >
      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <h1 style={{ fontSize: 28, marginBottom: 4 }}>{intl.formatMessage({ id: 'page.title' })}</h1>
        <p style={{ color: '#6b7280', margin: 0 }}>{intl.formatMessage({ id: 'page.subtitle' })}</p>
      </div>

      <GreetingSection locale={locale} />
      <StatsSection locale={locale} />
      <ProductsSection locale={locale} />
      <DatesSection locale={locale} />
      <RelativeTimeSection locale={locale} />
      <NumbersSection locale={locale} />
      <ListsSection locale={locale} />
      <DisplayNamesSection locale={locale} />
      <AdvancedICUSection locale={locale} />
      <Footer locale={locale} componentCount={COMPONENT_COUNT} />
    </div>
  );
};

export default ReactIntlRscDemo;
