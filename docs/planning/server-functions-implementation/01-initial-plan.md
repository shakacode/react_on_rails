# Server Functions Initial Implementation Plan

## Definition
Server Functions allow Client Components to call async functions executed on the server.

## Other Frameworks Implementation Way
### Next.js
Next.js framework re-render the whole app when a server action is executed, so all server components re-render and get latest server state.

### Waku
It executes the server function without re-rendering the app.

### React Implementation Sample
- Exists at [flight example on react repo](https://github.com/facebook/react/tree/main/fixtures/flight)
- Rerenders the whole app on server action execution

## Implementation Steps
1. Add support for registering server actions and transforming rsc and client bundles at `react-on-rails-rsc` webpack loader. Seems that the webpack loader currently doesn't transform the server functions on the client bundle. However, the react node loader at React repo seems that it looks for the `"user server"` directive and transform the server functions. Debug to find out why the server functions are not transformed inside react on rails pro dummy app client bundle.
1. Implement `callServer` function on client side that generates the server action id, encodes the server action arguments and send them to the back-end.
1. Implement backend endpoint to  receive the server action requests, decode it, execute and return the result. You need to decide if the whole app should be rendered or not.
1. Ensure progressive enhancement of the form works (when the page is not hydrated yet, form actions can still be submitted).
