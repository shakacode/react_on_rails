# Add Streaming and Interactivity to RSC Page

Before reading this document, please read the [Create React Server Component without SSR](./create-without-ssr.md) document.

## Make the React Server Component Page Progressively Load

React Server Components support progressive loading, which means they can be built as asynchronous functions that resolve and render after the initial HTML is sent to the client. This enables a better user experience by:

1. Showing initial content quickly while async data loads;
2. Maintaining interactivity while loading;
3. Streaming updates to the page as server components resolve.

This progressive enhancement approach allows React Server Components to efficiently handle data fetching and rendering without blocking the initial page load.

Let's create an `async` React Server Component that will be progressively loaded.

```js
// app/javascript/components/Posts.jsx
import React from 'react';
import fetch from 'node-fetch';
import _ from 'lodash';
import moment from 'moment';

const Posts = async () => {
  // Add artificial delay to simulate network latency
  await new Promise((resolve) => setTimeout(resolve, 1000));

  const posts = await (await fetch(`http://localhost:3000/api/posts`)).json();
  const postsByUser = _.groupBy(posts, 'user_id');
  const onePostPerUser = _.map(postsByUser, (group) => group[0]);

  return (
    <div>
      {onePostPerUser.map((post) => (
        <div style={{ border: '1px solid black', margin: '10px', padding: '10px' }}>
          <h1>{post.title}</h1>
          <p>{post.body}</p>
          <p>
            Created <span style={{ fontWeight: 'bold' }}>{moment(post.created_at).fromNow()}</span>
          </p>
          <img src="https://placehold.co/200" alt={post.title} />
        </div>
      ))}
    </div>
  );
};

export default Posts;
```

The async `Posts` component fetches and displays a list of posts, showing one post per user with title, body, timestamp and thumbnail image.

Let's add the Posts component to the React Server Component Page.

```js
// app/javascript/packs/components/ReactServerComponentPage.jsx
import React from 'react';
import ReactServerComponent from '../../components/ReactServerComponent';
import Posts from '../../components/Posts';

const ReactServerComponentPage = () => {
  return (
    <div>
      <ReactServerComponent />
      <Suspense fallback={<div>Loading...</div>}>
        <Posts />
      </Suspense>
    </div>
  );
};

export default ReactServerComponentPage;
```

The `Suspense` component is used to wrap the Posts component to handle its loading state. The `fallback` prop is used to display a loading message while the Posts component is loading.

## Run the Development Server

Run the development server:

```bash
bin/dev
```

Navigate to the React Server Component Page:

```
http://localhost:3000/react_server_component_without_ssr
```

When you open the page, you'll see the React Server Component render immediately, followed by the "Loading..." fallback state from the Suspense component. After a 1-second delay, the Posts component will render with the fetched data. This artificial delay helps demonstrate how React Server Components handle asynchronous operations and streaming:

1. The page loads instantly with the ReactServerComponent.
2. The Suspense fallback shows "Loading..." where the Posts will appear.
3. After the delay, the Posts component streams in and replaces "Loading...".

## How The Streaming Works

The streaming happens through the `rsc_payload/ReactServerComponentPage` fetch request that React on Rails Pro initiates when loading the page. The server keeps this connection open and sends data in chunks:

1. The initial chunk contains the immediately available content (ReactServerComponent).
2. When the Posts component's async operation completes, the server sends another chunk with its rendered content.
3. The browser progressively receives and renders these chunks, updating the page seamlessly.

This streaming approach means users see content as soon as it's ready, rather than waiting for everything to load before seeing anything. The `Suspense` boundary ensures a smooth transition between the loading state and the final content.

You can observe this streaming behavior in your browser's network tab: the `rsc/ReactServerComponentPage` request will show multiple chunks arriving over time, each one adding more content to your page.

## Add Interactivity

Let's add interactivity to the Posts component. Only client components can be interactive, so we'll create a new client component that helps us to show or hide the post image and call it `ToggleContainer`. It can receive any component as a child and toggle the visibility of the child component.

```js
// app/javascript/components/ToggleContainer.jsx
'use client';

import React, { useState } from 'react';

const ToggleContainer = ({ children }) => {
  const [isVisible, setIsVisible] = useState(false);

  return (
    <div>
      <button onClick={() => setIsVisible((prev) => !prev)}>Toggle</button>
      {isVisible && children}
    </div>
  );
};

export default ToggleContainer;
```

Now, let's use the `ToggleContainer` component to wrap the post image.

```js
// app/javascript/components/Posts.jsx
import ToggleContainer from './ToggleContainer';

const Posts = () => {
  // existing code..

  return (
    <div>
      {onePostPerUser.map((post) => (
        <div>
          {/* existing code.. */}
          <ToggleContainer>
            <img src="https://placehold.co/200" alt={post.title} />
          </ToggleContainer>
        </div>
      ))}
    </div>
  );
};

export default Posts;
```

Now when you visit the page, you'll see a "Toggle" button for each post. Clicking the button will show/hide that post's image. This demonstrates how we can add client-side interactivity to a React Server Component by creating a client component (`ToggleContainer`) that manages its own state.

The `ToggleContainer` is marked with [`'use client'`](https://react.dev/reference/rsc/use-client) directive, indicating it runs on the client-side and can handle user interactions. It uses the `useState` hook to maintain the visibility state of its children. Meanwhile, the parent `Posts` component remains a server component, fetching and rendering the initial posts data on the server.

It's important to note that while client components (like `ToggleContainer`) cannot directly import server components, they can receive server components as props (like children in this case). This is why we can pass the server-rendered image element as a child to our client-side `ToggleContainer` component. This pattern allows for flexible composition while maintaining the boundaries between server and client code.

This pattern allows us to optimize performance by keeping most of the component logic on the server while selectively adding interactivity where needed on the client.

## Checking The Network Requests

Let's check what bundles are being loaded for this page. By opening the browser's developer tools and going to the "Network" tab, you can see JavaScript bundles being loaded for this page.

![image](https://github.com/user-attachments/assets/369e4f76-7d1a-4545-a354-3cbecba35fcc)

Looking at the network requests, you'll notice two key JavaScript bundles:

1. The original `ReactServerComponentPage.js` bundle (1.4KB) - This contains the core server component code.
2. A new `client25.js` (can be different for you) bundle - This contains the client-side interactive code, specifically the `ToggleContainer` component and React hooks like `useState`.

The browser automatically knows to load this additional client bundle because of how React Server Components work:

1. When the server renders the RSC tree, it includes references to any client components used (in this case, `ToggleContainer`).
2. These references point to the specific JavaScript chunks needed to hydrate those client components.
3. The React runtime on the client then ensures those chunks are loaded before hydrating the interactive parts of the page.

This demonstrates one of the key benefits of React Server Components - automatic code splitting and loading of just the client-side JavaScript needed for interactivity, while keeping the bulk of the application logic on the server.

For more details on this architecture, see React's [Server Components documentation](https://react.dev/learn/thinking-in-react#how-react-server-components-work).

## Next Steps

Now that you understand how to add streaming and interactivity to React Server Components, you can proceed to the next article: [SSR React Server Components](./server-side-rendering.md) to learn how to enable server-side rendering (SSR) for your React Server Components.
