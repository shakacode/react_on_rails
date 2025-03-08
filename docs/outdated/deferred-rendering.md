# Deferred Rendering

Please see [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) if you are interested in code splitting using
[loadable-components.com](https://loadable-components.com/docs) with React on Rails.

---

What is code splitting? From the Webpack documentation:

> For big web apps it’s not efficient to put all code into a single file, especially if some blocks of code are only required under some circumstances. Webpack has a feature to split your codebase into “chunks” which are loaded on demand. Some other bundlers call them “layers”, “rollups”, or “fragments”. This feature is called “code splitting”.

## Server Rendering and Code Splitting

Let's say you're requesting a page that needs to fetch a code chunk from the server before it's able to render. If you do all your rendering on the client side, you don't have to do anything special. However, if the page is rendered on the server, you'll find that React will spit out the following error:

> Warning: React attempted to reuse markup in a container but the checksum was invalid. This generally means that you are using server rendering and the markup generated on the server was not what the client was expecting. React injected new markup to compensate which works but you have lost many of the benefits of server rendering. Instead, figure out why the markup being generated is different on the client or server:

> (client) `<!-- react-empty: 1 -`

> (server) `<div data-reactroot="`

Different markup is generated on the client than on the server. Why does this happen? When you register a component or Render-Function with `ReactOnRails.register`, React on Rails will by default render the component as soon as the page loads. However, code splitting requires that components render at a later time when the JavaScript chunks have loaded.

## Solution

To prevent this, you have to wait until the code chunk is fetched before doing the initial render on the client side. To accomplish this, React on Rails allows you to register a renderer. This works just like registering a Render-Function, except that the function you pass takes three arguments: `renderer(props, railsContext, domNodeId)`, and is responsible for calling `ReactDOM.render` or `ReactDOM.hydrate` to render the component to the DOM. React on rails will automatically detect when a Render-Function takes three arguments, and will **not** call `ReactDOM.render` or `ReactDOM.hydrate`, instead allowing you to control the initial render yourself. Note, you have to be careful to call `ReactDOM.hydrate` rather than `ReactDOM.render` if you are server rendering.

## Server vs. Client Code Caveats

If you're going to try to do code splitting with server rendered routes, you'll probably need to use separate route definitions for client and server to prevent code splitting from happening for the server bundle. The server bundle should be one file containing all the JavaScript code. This will require you to have separate Webpack configurations for client and server.

Do not attempt to register a renderer function on the server. Instead, register either a Render-Function or a component. If you register a renderer in the server bundle, you'll get an error when React on Rails tries to server render the component.

## React on Rails Pro

[React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) includes a complete setup using this technique for code splitting using
[loadable-components.com](https://loadable-components.com/docs) with React on Rails.
