# Client-Side Rendering vs. Server-Side Rendering

*Also, see [our react server-rendering documentation](https://www.shakacode.com/react-on-rails/docs/basics/react-server-rendering).*

In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript. The default is to use [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. We recommend using [mini_racer](https://github.com/discourse/mini_racer) as ExecJS's runtime.

If you want to maximize the perfomance of your server rendering, then you want to use React on Rails Pro which uses NodeJS to do the server rendering. See the [docs for React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki).

If you open the HTML source of any web page using React on Rails, you'll see the 3 parts of React on Rails rendering:

1. A script tag containing the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads, using this data to build and initialize your React components.
2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component.
3. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note: these server side logs can be configured only to be sent to the server logs.

**Note**: If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.

# Different Server-Side Rendering Code (and a Server-Specific Bundle)

You may want different code for your server-rendered components running server side versus client side. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. One way to handle this is conditional code like `if (window) { doClientOnlyCode() }`.

Another way is to use a separate webpack configuration file that can use a different server side entry file, like  'serverRegistration.js' as opposed to 'clientRegistration.js.' That would set up different code for server rendering.

For details on techniques to use different code for client and server rendering, see: [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352). _Requires creating a free account._
