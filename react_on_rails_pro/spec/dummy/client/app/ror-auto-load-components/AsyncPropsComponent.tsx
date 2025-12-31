/// <reference types="react/experimental" />

import * as React from 'react';
import { Suspense } from 'react';
import { WithAsyncProps } from 'react-on-rails-pro';

type SyncPropsType = {
  name: string;
  age: number;
  description: string;
};

type AsyncPropsType = {
  books: string[];
  researches: string[];
};

type PropsType = WithAsyncProps<AsyncPropsType, SyncPropsType>;

const AsyncArrayComponent = async ({ items }: { items: Promise<string[]> }) => {
  const resolvedItems = await items;

  return (
    <ol>
      {resolvedItems.map((value) => (
        <li key={value}>{value}</li>
      ))}
    </ol>
  );
};

const AsyncPropsComponent = ({ name, age, description, getReactOnRailsAsyncProp }: PropsType) => {
  const booksPromise = getReactOnRailsAsyncProp('books');
  const researchesPromise = getReactOnRailsAsyncProp('researches');

  return (
    <div>
      <h1>Async Props Component</h1>
      <p>Name: {name}</p>
      <p>Age: {age}</p>
      <p>Description: {description}</p>

      <h2>Books</h2>
      <Suspense fallback={<p>Loading Books...</p>}>
        <AsyncArrayComponent items={booksPromise} />
      </Suspense>

      <h2>Researches</h2>
      <Suspense fallback={<p>Loading Researches...</p>}>
        <AsyncArrayComponent items={researchesPromise} />
      </Suspense>
    </div>
  );
};

export default AsyncPropsComponent;
