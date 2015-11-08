# Server Rendering Tips

- Your code can't reference `document`. Server side JS execution does not have access to `document`, so jQuery and some
  other libs won't work in this environment. You can debug this by putting in `console.log`
  statements in your code.
- You can conditionally avoid running code that references document by passing in a boolean prop to your top level react
  component. Since the passed in props Hash from the view helper applies to client and server side code, the best way to
  do this is to use a generator function.
- If you're serious about server rendering, it's worth the effort to have different entry points for client and server rendering. It's worth the extra complexity.

You might also do something like this in some file for your top level component:
```javascript
global.App = () => <MyComponent serverSide={true} />;
```

The point is that you have separate files for top level client or server side, and you pass some extra option indicating that rendering is happening server sie.
