# Communication between React Components and Redux Reducers

## Communication Between Components
See https://facebook.github.io/react/tips/communicate-between-components.html

# Redux Reducers
Documentation of generated Redux code for reducers.

## Example
The `helloWorld/reducers/index.jsx` example that results from running the generator with the Redux option may be slightly confusing because of its simplicity. For clarity, what follows is a more fleshed-out example of what a reducer might look like:

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
