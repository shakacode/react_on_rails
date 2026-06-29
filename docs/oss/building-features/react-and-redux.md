# Legacy Redux Reducer Guidance

Redux remains supported for existing React on Rails apps and advanced pages that need one client store shared across multiple React roots. For new apps, prefer local component state for island-specific UI, Rails props plus server-state tools for server-owned data, and reach for Redux only when those smaller patterns do not fit.

## Communication Between Components

See [Sharing State Between Components](https://react.dev/learn/sharing-state-between-components).

## Redux Reducers

The `helloWorld/reducers/index.jsx` example from the hidden legacy Redux generator may be slightly confusing because of its simplicity. For clarity, what follows is a more fleshed-out example of what a reducer might look like:

```javascript
import usersReducer from './usersReducer';
import blogPostsReducer from './blogPostsReducer';
import commentsReducer from './commentsReducer';
// ...

import { $$initialState as $$usersState } from './usersReducer';
import { $$initialState as $$blogPostsState } from './blogPostsReducer';
import { $$initialState as $$commentsState } from './commentsReducer';
// ...

export default {
  $$usersStore: usersReducer,
  $$blogPostsStore: blogPostsReducer,
  $$commentsStore: commentsReducer,
  // ...
};

export const initialStates = {
  $$usersState,
  $$blogPostsState,
  $$commentsState,
  // ...
};
```
