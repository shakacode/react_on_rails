## Code Structure
The generated client code follows our organization scheme. Each unique set of functionality, is given its own folder inside of `client/app/bundles`. This encourages for modularity of *domains*.

Inside of the generated "HelloWorld" domain you will find the following folders:

+  `startup`: two types of files, one that return a container component and implement any code that differs between client and server code (if using server-rendering), and a `clientRegistration` file that exposes the aforementioned files (as well as a `serverRegistration` file if using server rendering). These registration files are what webpack is using as an entry point.
+ `containers`: "smart components" (components that have functionality and logic that is passed to child "dumb components").
+ `components`: includes "dumb components", or components that simply render their properties and call functions given to them as properties by a parent component. Ultimately, at least one of these dumb components will have a parent container component.

You may also notice the `app/lib` folder. This is for any code that is common between bundles and therefore needs to be shared (for example, middleware).
