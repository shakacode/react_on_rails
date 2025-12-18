import * as React from 'react';
import { Suspense } from 'react';
import b from 'benny';
import renderComponent from './streamServerRenderReactComponentHelper';
import { text } from 'stream/consumers';

const component = () => <div>Very Simple Component</div>;

const PromiseContainer = async ({ promise }: { promise: Promise<string> }) => {
  const value = await promise;
  return <p>Resolved Value: &quot;{value}&quot;</p>;
};

const Container = ({ delay }: { delay: number }) => {
  const promise = new Promise<string>((resolve) => {
    setTimeout(() => {
      resolve(`Async Value after "${delay} ms"`);
    }, delay);
  });
  return (
    <div>
      <h1>Container Header</h1>
      <Suspense fallback={<p>Loading The Async Value....</p>}>
        <PromiseContainer promise={promise} />
      </Suspense>
    </div>
  );
};

b.suite(
  'streamServerRenderReactComponent',
  b.add('warm up', async () => {
    const result = renderComponent(component);
    await text(result);
  }),
  b.add('simple component', async () => {
    const result = renderComponent(component);
    await text(result);
  }),
  b.add('multiple simple component', async () => {
    const result1 = renderComponent(component);
    const result2 = renderComponent(component);
    await Promise.all([text(result1), text(result2)]);
  }),
  b.add('simple async component', async () => {
    const result = renderComponent(Container, { delay: 0 });
    await text(result);
  }),
  b.add('multiple simple async component', async () => {
    const result1 = renderComponent(Container, { delay: 0 });
    const result2 = renderComponent(Container, { delay: 0 });
    await Promise.all([text(result1), text(result2)]);
  }),
  b.add('delayed async component', async () => {
    const result = renderComponent(Container, { delay: 10 });
    await text(result);
  }),
  b.add('multiple delayed async component', async () => {
    const result1 = renderComponent(Container, { delay: 10 });
    const result2 = renderComponent(Container, { delay: 10 });
    await Promise.all([text(result1), text(result2)]);
  }),
  b.save({ file: 'stream' }),
).catch(() => {
  console.log('Error');
});
