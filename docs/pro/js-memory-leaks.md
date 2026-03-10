# JS Memory Leaks

## Finding Memory Leaks

For memory leaks, see [node-memwatch](https://github.com/marcominetti/node-memwatch). Use the `—inspect` flag to make and compare heap snapshots.

## Causes of Memory Leaks

### Mobx (mobx-react)

```js
import { useStaticRendering } from "mobx-react";

const App = (props, railsContext) => {
  const { location, serverSide } = railsContext;
  const context = {};

  useStaticRendering(true);
```

- See details here: [Mobx site](https://github.com/mobxjs/mobx-react#server-side-rendering-with-usestaticrendering)
