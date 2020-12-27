# Rails/Webpacker React Integration Options

You only _need_ props hydration if you need SSR. However, there's no good reason to
have your app make a second round trip to the Rails server to get initialization props.

**Server-Side Rendering (SSR)** results in Rails rendering HTML for your React components. The main reasons to use SSR are better SEO and pages display more quickly. 

These gems provide advanced integration of React with [rails/webpacker](https://github.com/rails/webpacker): 

| Gem | Props Hydration | Server-Side-Rendering (SSR) | SSR with HMR | SSR with React-Router | SSR with Code Splitting | Node SSR |
| --- | --------------- | --- | --------------------- | ----------------------| ------------------------|----|
| [shakacode/react_on_rails](https://github.com/shakacode/react_on_rails) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| [react-rails](https://github.com/reactjs/react-rails)  | ✅ | ✅ |  | | | | |
| [webpacker-react](https://github.com/renchap/webpacker-react) | ✅ | | | | | | |

Note, Node SSR for React on Rails requires [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro).

---

As mentioned, you don't _need_ to use a gem to integrate Rails with React.

If you're not concerned with view helpers to pass props or server rendering, can do it yourself:

```erb
<%# views/layouts/application.html.erb %>

<%= content_tag :div,
  id: "hello-react",
  data: {
    message: 'Hello!',
    name: 'David'
}.to_json do %>
<% end %>
```

```js
// app/javascript/packs/hello_react.js

const Hello = props => (
  <div className='react-app-wrapper'>
    <img src={clockIcon} alt="clock" />
    <h5 className='hello-react'>
      {props.message} {props.name}!
    </h5>
  </div>
)

// Render component with data
document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById('hello-react')
  const data = JSON.parse(node.getAttribute('data'))

  ReactDOM.render(<Hello {...data} />, node)
})
```
