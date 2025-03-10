# Selective Hydration in React Server Components

## Introduction

React has introduced a powerful enhancement to server-side rendering through streaming and React Server Components - selective hydration. This feature fundamentally changes how pages become interactive in the browser.

Previously, with traditional server-side rendering, the browser had to wait for the entire page to load and all JavaScript to execute before any part could become interactive. This created a noticeable delay in page interactivity, especially for larger applications.

With selective hydration, React can now hydrate different parts of the page independently and asynchronously. Key benefits include:

- Components can become interactive as soon as their code and data are available, without waiting for the entire page
- React automatically prioritizes hydrating components that users are trying to interact with

This approach significantly improves both perceived and actual performance by making the most relevant parts interactive first.

## Try Selective Hydration with React Server Component Page

Let's try selective hydration with the React Server Component Page we created in the [SSR React Server Components](./ssr-react-server-components.md).

Let's add a component that is very slow to load into the page.

```jsx
const LongWaitingComponent = async () => {
  await new Promise((resolve) => setTimeout(resolve, 5000));
  return <div>Long waiting component</div>;
};
```

Add the component to the page.

```jsx
// app/javascript/packs/components/ReactServerComponentPage.jsx
const ReactServerComponentPage = () => {
  return (
    <div>
      <ReactServerComponent />
      <Suspense fallback={<div>Loading The Long Waiting Component...</div>}>
        <LongWaitingComponent />
      </Suspense>
      <Suspense fallback={<div>Loading...</div>}>
        <Posts />
      </Suspense>
    </div>
  );
};
```

## Fixing Compatibility Issue that Blocks Hydration

When you run the page, you should see "Loading The Long Waiting Component..." in the browser for 5 seconds. Then, the component is rendered and the page becomes interactive.

You can notice that the page doesn't become interactive until the Long Waiting Component is rendered, which contradicts what we discussed about selective hydration.

This happens because React on Rails by default adds the scripts that hydrate components as `defer` scripts, which only execute after the whole page is loaded. Since the page is being streamed, this means the scripts won't run until all components have been server-side rendered and streamed to the browser.

This default behavior was kept for backward compatibility, as there were previously race conditions that could occur when using `async` scripts before the page fully loaded. However, these race conditions have been fixed in the latest React on Rails release.

To enable true selective hydration, we need to configure React on Rails to load scripts as `async` scripts by adding `defer_generated_component_packs: false` to the React on Rails initializer:

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.defer_generated_component_packs = false
end
```

Now, when you run the page, you can see that while the Long Waiting Component is loading ⏳, the other components are interactive ✨🖱️

## Conclusion

Selective hydration is a powerful feature that allows React to become interactive as soon as its code and data are available, without waiting for the entire page to load. This approach significantly improves both perceived and actual performance by making the most relevant parts interactive first.

## Next Steps

Now that you understand how to use selective hydration in React Server Components, you can proceed to the next article: [How React Server Components Work](how-react-server-components-work.md) to learn about the technical details and underlying mechanisms of React Server Components.
