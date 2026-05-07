/* PPR demo — multiple Suspense boundaries with mixed static / postponed content. */
import React, { Suspense } from 'react';
import { usePostpone } from 'react-on-rails-pro/postpone';

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/* ─── Static (in-shell) async components ───────────────────────────────────── */

const FastStaticHeader = async () => {
  await sleep(50);
  return (
    <header data-testid="ppr-static-header" style={{ padding: '12px', background: '#e3f2fd' }}>
      <h2>Static Header</h2>
      <p>Resolves at ~50ms — always in the cached shell.</p>
    </header>
  );
};

const SlowStaticProductGrid = async () => {
  await sleep(900);
  return (
    <section data-testid="ppr-static-products" style={{ padding: '12px', background: '#e8f5e9' }}>
      <h2>Popular Products (slow static, ~900ms)</h2>
      <ul>
        <li>Widget A — $19.99</li>
        <li>Widget B — $29.99</li>
        <li>Widget C — $9.99</li>
      </ul>
    </section>
  );
};

const SlowerStaticReviews = async () => {
  await sleep(2500);
  return (
    <section data-testid="ppr-static-reviews" style={{ padding: '12px', background: '#fff3e0' }}>
      <h2>Reviews (slower static, ~2.5s)</h2>
      <blockquote>“Excellent quality.” — Anonymous</blockquote>
      <blockquote>“Fast shipping!” — Anonymous</blockquote>
    </section>
  );
};

/* ─── Dynamic (postponed) async components ─────────────────────────────────── */

interface DynamicProps {
  currentTime?: string;
  userName?: string;
  cartItemCount?: number;
}

/* Reads request-varying data → calls usePostpone() to declare itself dynamic. */
const DynamicCartBadge = async ({ cartItemCount }: DynamicProps) => {
  // PRERENDER: throws never-resolving promise → boundary becomes a postponed hole.
  // RESUME:    no-op → component renders normally with the cartItemCount prop.
  usePostpone('reads cart cookie');
  await sleep(20); // simulate cart cookie lookup
  return (
    <div data-testid="ppr-dynamic-cart" style={{ padding: '12px', background: '#fce4ec' }}>
      <h2>Cart Badge (dynamic)</h2>
      <p>
        Items in cart: <strong>{cartItemCount ?? 0}</strong>
      </p>
    </div>
  );
};

const DynamicUserGreeting = async ({ userName }: DynamicProps) => {
  usePostpone('reads session.current_user');
  await sleep(20);
  return (
    <div data-testid="ppr-dynamic-greeting" style={{ padding: '12px', background: '#f3e5f5' }}>
      <h2>User Greeting (dynamic)</h2>
      <p>
        Hello, <strong>{userName ?? 'guest'}</strong>!
      </p>
    </div>
  );
};

const DynamicTimestamp = async ({ currentTime }: DynamicProps) => {
  usePostpone('shows current request time');
  return (
    <div data-testid="ppr-dynamic-timestamp" style={{ padding: '12px', background: '#fff9c4' }}>
      <h2>Request Timestamp (dynamic)</h2>
      <p>
        Generated at: <code>{currentTime ?? '(prerender)'}</code>
      </p>
    </div>
  );
};

/* ─── Nested boundaries: outer postpones, inner static is inside the hole ──── */

const NestedInnerStatic = async () => {
  await sleep(100);
  return <p>Inner-static content (lives inside the postponed hole).</p>;
};

const NestedOuterDynamic = async ({ currentTime }: DynamicProps) => {
  usePostpone('outer boundary intentionally postpones');
  await sleep(20);
  return (
    <div style={{ padding: '8px', border: '1px dashed #999' }}>
      <h3>Outer dynamic boundary</h3>
      <Suspense fallback={<p>(inner static fallback)</p>}>
        <NestedInnerStatic />
      </Suspense>
      <p>
        <small>Resolved at: {currentTime ?? '(prerender)'}</small>
      </p>
    </div>
  );
};

/* ─── Top-level page ───────────────────────────────────────────────────────── */

const PPRDemo: React.FC<DynamicProps> = (props) => (
  <main
    data-testid="ppr-demo-root"
    style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 720, margin: '0 auto' }}
  >
    <h1>PPR Comprehensive Demo</h1>
    <p>
      This page exercises every PPR edge case: fast/slow/slower static boundaries, multiple dynamic
      boundaries, and a nested Suspense tree where the outer boundary postpones.
    </p>

    {/* Synchronous content — always in the shell, no Suspense needed. */}
    <section data-testid="ppr-sync-banner" style={{ padding: '12px', background: '#cfd8dc' }}>
      <h2>Synchronous banner</h2>
      <p>This text is rendered synchronously and is always in the shell.</p>
    </section>

    <Suspense fallback={<header data-testid="ppr-static-header-fallback">Loading header…</header>}>
      <FastStaticHeader />
    </Suspense>

    <Suspense fallback={<section data-testid="ppr-static-products-fallback">Loading products…</section>}>
      <SlowStaticProductGrid />
    </Suspense>

    <Suspense fallback={<div data-testid="ppr-dynamic-cart-fallback">Loading cart…</div>}>
      <DynamicCartBadge {...props} />
    </Suspense>

    <Suspense fallback={<section data-testid="ppr-static-reviews-fallback">Loading reviews…</section>}>
      <SlowerStaticReviews />
    </Suspense>

    <Suspense fallback={<div data-testid="ppr-dynamic-greeting-fallback">Loading greeting…</div>}>
      <DynamicUserGreeting {...props} />
    </Suspense>

    <Suspense fallback={<div data-testid="ppr-dynamic-timestamp-fallback">Loading timestamp…</div>}>
      <DynamicTimestamp {...props} />
    </Suspense>

    <Suspense fallback={<div data-testid="ppr-nested-fallback">Loading nested boundary…</div>}>
      <NestedOuterDynamic {...props} />
    </Suspense>

    <footer data-testid="ppr-sync-footer" style={{ padding: '12px', marginTop: 16, background: '#eceff1' }}>
      <small>Synchronous footer — always in the shell.</small>
    </footer>
  </main>
);

export default PPRDemo;
