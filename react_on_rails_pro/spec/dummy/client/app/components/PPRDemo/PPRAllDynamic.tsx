/* PPR demo — every Suspense boundary postpones. The cached shell consists only of the synchronous
 * surrounding markup; every section is filled at request time via resumeToPipeableStream. */
import React, { Suspense } from 'react';
import { usePostpone } from 'react-on-rails-pro/postpone';

interface Props {
  currentTime?: string;
  userName?: string;
}

const SectionA = async ({ currentTime }: Props) => {
  usePostpone('A reads request time');
  return (
    <p data-testid="ppr-all-dynamic-a">
      A — generated at <code>{currentTime ?? '(prerender)'}</code>
    </p>
  );
};

const SectionB = async ({ userName }: Props) => {
  usePostpone('B reads session');
  return (
    <p data-testid="ppr-all-dynamic-b">
      B — hello <strong>{userName ?? '(prerender)'}</strong>
    </p>
  );
};

const SectionC = async () => {
  usePostpone('C is intentionally postponed');
  return <p data-testid="ppr-all-dynamic-c">C — random uuid: {crypto.randomUUID?.() ?? '(no crypto)'}</p>;
};

const PPRAllDynamic: React.FC<Props> = (props) => (
  <main
    data-testid="ppr-all-dynamic-root"
    style={{ fontFamily: 'system-ui, sans-serif', maxWidth: 720, margin: '0 auto' }}
  >
    <h1>PPR — All Dynamic</h1>
    <p>Every section postpones. The cached shell is just this surrounding HTML.</p>
    <Suspense fallback={<p data-testid="ppr-all-dynamic-a-fallback">Loading A…</p>}>
      <SectionA {...props} />
    </Suspense>
    <Suspense fallback={<p data-testid="ppr-all-dynamic-b-fallback">Loading B…</p>}>
      <SectionB {...props} />
    </Suspense>
    <Suspense fallback={<p data-testid="ppr-all-dynamic-c-fallback">Loading C…</p>}>
      <SectionC {...props} />
    </Suspense>
    <p data-testid="ppr-all-dynamic-sync">Sync footer — always in the shell.</p>
  </main>
);

export default PPRAllDynamic;
