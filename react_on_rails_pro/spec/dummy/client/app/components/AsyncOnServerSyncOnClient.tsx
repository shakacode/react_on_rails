'use client';

import * as React from 'react';
import { Suspense, useEffect } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

const AsyncComponentOnServer = async ({
  promise,
  children,
}: {
  promise: Promise<React.ReactNode>;
  children: React.ReactNode;
}) => {
  await promise;
  return children;
};

const SyncComponentOnClient = ({ children }: { children: React.ReactNode }) => {
  return children;
};

const ComponentToUse = typeof window === 'undefined' ? AsyncComponentOnServer : SyncComponentOnClient;

const LoadingComponent = ({ content }: { content: string }) => {
  console.log(`[AsyncOnServerSyncOnClient] LoadingComponent rendered ${content}`);
  return <div>{content}</div>;
};

const RealComponent = ({ content, children }: { content: string; children?: React.ReactNode }) => {
  console.log(`[AsyncOnServerSyncOnClient] RealComponent rendered ${content}`);
  useEffect(() => {
    console.log(`[AsyncOnServerSyncOnClient] RealComponent has been mounted ${content}`);
  }, [content]);
  return <div>{children ?? content}</div>;
};

function AsyncContent() {
  console.log('[AsyncOnServerSyncOnClient] AsyncContent rendered');
  const promise1 = new Promise((resolve) => {
    setTimeout(() => {
      resolve(undefined);
    }, 1000);
  });
  const promise2 = new Promise((resolve) => {
    setTimeout(() => {
      resolve(undefined);
    }, 2000);
  });
  const promise3 = new Promise((resolve) => {
    setTimeout(() => {
      resolve(undefined);
    }, 3000);
  });

  useEffect(() => {
    console.log('[AsyncOnServerSyncOnClient] AsyncContent has been mounted');
  }, []);

  return (
    <div>
      <Suspense fallback={<LoadingComponent content="Loading Suspense Boundary1" />}>
        {/* @ts-expect-error - ComponentToUse is conditionally typed based on environment */}
        <ComponentToUse promise={promise1}>
          <RealComponent content="Async Component 1 from Suspense Boundary1 (1000ms server side delay)" />
        </ComponentToUse>
        {/* @ts-expect-error - ComponentToUse is conditionally typed based on environment */}
        <ComponentToUse promise={promise2}>
          <RealComponent content="Async Component 2 from Suspense Boundary1 (2000ms server side delay)" />
        </ComponentToUse>
      </Suspense>
      <Suspense fallback={<LoadingComponent content="Loading Suspense Boundary2" />}>
        {/* @ts-expect-error - ComponentToUse is conditionally typed based on environment */}
        <ComponentToUse promise={promise3}>
          <RealComponent content="Async Component 1 from Suspense Boundary2 (3000ms server side delay)" />
        </ComponentToUse>
      </Suspense>
      <Suspense fallback={<LoadingComponent content="Loading Suspense Boundary3" />}>
        {/* @ts-expect-error - ComponentToUse is conditionally typed based on environment */}
        <ComponentToUse promise={promise1}>
          <RealComponent content="Async Component 1 from Suspense Boundary3 (1000ms server side delay)" />
        </ComponentToUse>
      </Suspense>
      <Suspense fallback={<LoadingComponent content="Loading Server Component on Suspense Boundary4" />}>
        {/* @ts-expect-error - ComponentToUse is conditionally typed based on environment */}
        <ComponentToUse promise={promise2}>
          <RealComponent content="Server Component from Suspense Boundary4 (2000ms server side delay)">
            <RSCRoute componentName="SimpleComponent" componentProps={{}} />
          </RealComponent>
        </ComponentToUse>
      </Suspense>
    </div>
  );
}

export default AsyncContent;
