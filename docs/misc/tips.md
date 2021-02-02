# Tips
+ **DO NOT RUN `rails s`** and instead run 

    `foreman start -f Procfile.dev`

    to automatically start the webpack file watchers that will regenerate your JavaScript. Note, RSpec does not automatically rebuild the bundle files, so you could get incorrect results from your tests if you change the client code and do not rebuild the bundles. The same problem occurs when pulling down changes from GitHub and running tests without first rebuilding the bundles.
+ The default for rendering right now is `prerender: false`. **NOTE:**  Server side rendering does not work for some components that use an async setup for server rendering. You can configure the default for prerender in your config.
+ You can expose either a React component or a function that returns a React component. If you wish to create a React component via a function, rather than simply props, then you need to set the property "generator" on that helper invocation to true (or change the defaults). When that is done, the function is invoked with a single parameter of "props", and that function should return a React element.
+ Be sure you can first render your react component **client only** before you try to debug server rendering!
+ Open up the HTML source and take a look at the generated HTML and the JavaScript to see what's going on under the covers. Note that when server rendering is turned on, then you'll see the server rendered react components. When server rendering is turned off, then you'll only see the `div` element where the in-line JavaScript will render the component. You might also notice how the props you pass (a Ruby Hash) becomes in-line JavaScript on the HTML page.
