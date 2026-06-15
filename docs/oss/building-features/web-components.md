# Web Components

React on Rails supports native [Web Components](https://developer.mozilla.org/en-US/docs/Web/API/Web_components) (Custom Elements) alongside React components. You can use web components in server-rendered React components, client-only React components, and directly in ERB templates.

## How It Works

Web components are browser-native custom HTML elements. React on Rails treats them like any other HTML tag — the custom element tags pass through server rendering as-is, then upgrade to interactive components once JavaScript loads on the client.

```
Server renders:   <my-counter value="5"></my-counter>     ← plain HTML tag
Browser receives: empty custom element (no shadow content)
JS loads:         connectedCallback() fires → builds the UI
```

> [!NOTE]
> Web component tags appear in the server-rendered HTML, but their **internal content** (shadow DOM, dynamically created children) is only created client-side after JavaScript loads and the element class is registered with `customElements.define()`.

## Defining a Web Component

Create a TypeScript (or JavaScript) file that defines your custom element class:

```typescript
// client/app/web-components/app-greeting.ts

export class AppGreeting extends HTMLElement {
  static observedAttributes = ['name', 'variant'];

  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.render();
  }

  attributeChangedCallback(_name: string, _oldValue: string | null, _newValue: string | null) {
    this.render();
  }

  private render() {
    const name = this.getAttribute('name') || 'World';
    this.shadowRoot!.innerHTML = `
      <style>
        :host { display: block; }
        .greeting { padding: 16px; border-radius: 8px; border: 1px solid #e5e7eb; }
      </style>
      <div class="greeting">
        <p class="name"></p>
        <slot></slot>
      </div>
    `;
    this.shadowRoot!.querySelector('.name')!.textContent = `Hello, ${name}!`;
  }
}

if (typeof customElements !== 'undefined' && !customElements.get('app-greeting')) {
  customElements.define('app-greeting', AppGreeting);
}
```

The `typeof customElements !== 'undefined'` guard prevents errors during server-side rendering, where browser APIs are not available.

## Registering Web Components

Create a central registration file that imports all your web component definitions:

```typescript
// client/app/web-components/register.ts

export {};

if (typeof window !== 'undefined') {
  void import('./app-greeting');
  void import('./app-counter');
  void import('./app-toggle');
}
```

Import this file from your client bundle entry point:

```typescript
// client/app/packs/client-bundle.ts

import ReactOnRails from 'react-on-rails/client';
import '../web-components/register';

// ... rest of your registrations
```

The `typeof window` guard ensures dynamic imports only run in the browser. On the server, only the custom element tags are rendered — no JavaScript class registration occurs.

## Using in React Components

### Server-Rendered Components (`prerender: true`)

Web component tags work in server-rendered React components. The tags are included in the initial HTML response with their attributes:

If you use TypeScript, declare your custom element tags so JSX type-checking accepts them:

```typescript
// client/app/types/web-components.d.ts

import 'react';

declare module 'react' {
  namespace JSX {
    interface IntrinsicElements {
      'app-greeting': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement> & {
        name?: string;
        variant?: string;
      };
      'app-counter': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement> & {
        value?: string;
        label?: string;
      };
    }
  }
}
```

Then use the tags in your component:

```tsx
// client/app/startup/Dashboard.tsx

const Dashboard: React.FC<{ userName: string }> = ({ userName }) => (
  <div>
    <h1>Welcome</h1>
    <app-greeting name={userName} variant="primary">
      <span>Your dashboard is ready.</span>
    </app-greeting>
    <app-counter value="0" label="Tasks" />
  </div>
);

export default Dashboard;
```

```erb
<%# app/views/pages/dashboard.html.erb %>
<%= react_component("Dashboard", props: { userName: @user.name }, prerender: true) %>
```

The server output will contain:

```html
<app-greeting name="Alice" variant="primary">
  <span>Your dashboard is ready.</span>
</app-greeting>
<app-counter value="0" label="Tasks"></app-counter>
```

These are plain HTML tags until JavaScript loads and the custom element classes are registered. Slotted content (children inside the tags) is part of the server HTML and is visible immediately.

### Client-Only Components (`prerender: false`)

Client-rendered React components work identically. Use refs and event listeners to sync web component state with React:

```tsx
// client/app/startup/InteractiveDemo.tsx

import React, { useEffect, useRef, useState } from 'react';

const InteractiveDemo: React.FC = () => {
  const counterRef = useRef<HTMLElement>(null);
  const [count, setCount] = useState(0);

  useEffect(() => {
    const el = counterRef.current;
    if (!el) return;

    const handler = (e: Event) => {
      setCount((e as CustomEvent).detail.value);
    };

    el.addEventListener('counter-change', handler);
    return () => el.removeEventListener('counter-change', handler);
  }, []);

  return (
    <div>
      <app-counter ref={counterRef} value={String(count)} label="Items" />
      <p>React sees count: {count}</p>
    </div>
  );
};

export default InteractiveDemo;
```

Web components are already registered by the `client-bundle.ts` import shown above — there is no need to import `register.ts` again in individual components.

> [!TIP]
> React 19 sets properties directly on custom elements when a property of that name exists on the element instance. For attributes that must be strings (like `value`), explicitly convert with `String()`.

## Using Directly in ERB

Web components work in ERB templates without any React wrapper:

```erb
<%# app/views/pages/status.html.erb %>

<app-greeting name="<%= @user.name %>" variant="success">
  <span>Welcome back!</span>
</app-greeting>

<app-counter value="<%= @initial_count %>" label="Page Views"></app-counter>
```

This requires the client bundle (which imports `register.ts`) to be loaded on the page.

## Shadow DOM Modes

Web components support three encapsulation levels:

| Mode                      | External CSS Affects It? | External JS Can Access Children?              | `element.shadowRoot` |
| ------------------------- | ------------------------ | --------------------------------------------- | -------------------- |
| **Light DOM** (no shadow) | Yes                      | Yes, via `querySelector`                      | `null`               |
| **Open Shadow**           | No                       | Yes, via `element.shadowRoot.querySelector()` | Accessible           |
| **Closed Shadow**         | No                       | No                                            | `null`               |

### Light DOM (No Shadow)

Children are part of the regular DOM. External CSS styles them, and external JavaScript can query them directly.

```typescript
export class WcLightDom extends HTMLElement {
  connectedCallback() {
    this.innerHTML = `<p class="message">I'm in the light DOM</p>`;
  }
}
```

### Open Shadow DOM

Styles are encapsulated. External JavaScript can access the shadow tree via `element.shadowRoot`:

```typescript
export class WcOpenShadow extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
  }

  connectedCallback() {
    this.shadowRoot!.innerHTML = `
      <style>.message { color: blue; }</style>
      <p class="message">I'm in open shadow DOM</p>
    `;
  }
}
```

### Closed Shadow DOM

Maximum encapsulation. External code cannot access the shadow tree. Expose behavior through public methods:

```typescript
export class WcClosedShadow extends HTMLElement {
  private _shadow: ShadowRoot;

  constructor() {
    super();
    this._shadow = this.attachShadow({ mode: 'closed' });
  }

  connectedCallback() {
    this._shadow.innerHTML = `
      <style>.count { font-size: 24px; }</style>
      <span class="count">0</span>
    `;
  }

  getCount(): number {
    return parseInt(this._shadow.querySelector('.count')!.textContent || '0', 10);
  }

  reset(): void {
    this._shadow.querySelector('.count')!.textContent = '0';
  }
}
```

## Event Communication

Web components communicate with React through [Custom Events](https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent). Two key options control event propagation:

- **`bubbles: true`** — event propagates up the DOM tree
- **`composed: true`** — event crosses shadow DOM boundaries

```typescript
// Inside a shadow DOM web component:
this.dispatchEvent(
  new CustomEvent('status-change', {
    detail: { status: 'active' },
    bubbles: true,
    composed: true, // required to reach React listeners outside shadow DOM
  }),
);
```

In React, listen with `addEventListener` on a ref:

```tsx
useEffect(() => {
  const el = ref.current;
  const handler = (e: Event) => {
    const { status } = (e as CustomEvent).detail;
    setStatus(status);
  };
  el?.addEventListener('status-change', handler);
  return () => el?.removeEventListener('status-change', handler);
}, []);
```

> [!WARNING]
> Events with `composed: false` are **trapped inside shadow DOM** and will not reach React event listeners. Always use `composed: true` when you need React to observe events dispatched from inside a shadow root.

## CSS Behavior

### Style Encapsulation

Shadow DOM prevents external CSS from affecting internal elements. This means global stylesheets and Tailwind classes do not reach inside shadow DOM components.

### CSS Custom Properties Pierce Shadow DOM

CSS custom properties (variables) are the exception — they inherit through all shadow boundaries:

```css
/* In your global CSS or ERB layout */
:root {
  --brand-color: #3b82f6;
  --brand-bg: #eff6ff;
}
```

```typescript
// Inside a shadow DOM web component:
this.shadowRoot!.innerHTML = `
  <style>
    .card { background: var(--brand-color, #000); }
  </style>
  <div class="card">Themed by CSS variables</div>
`;
```

### `::part()` for Selective External Styling

Open shadow DOM components can expose elements for external styling with the `part` attribute:

```typescript
// Web component template:
this.shadowRoot!.innerHTML = `
  <h2 part="title">Component Title</h2>
  <p part="body">Component body text</p>
`;
```

```css
/* External CSS can style exposed parts: */
my-component::part(title) {
  color: navy;
  font-size: 24px;
}
```

## Slots

Slots project light DOM content into shadow DOM layout positions. Slotted content lives in the light DOM — it is visible in the server-rendered HTML and can be queried with `querySelector` from outside:

```tsx
<wc-card>
  <span slot="header">This is SSR'd and visible immediately</span>
  <p>Default slot content, also in the server HTML</p>
</wc-card>
```

```typescript
// Web component definition:
this.shadowRoot!.innerHTML = `
  <div class="card">
    <div class="header"><slot name="header"></slot></div>
    <div class="body"><slot></slot></div>
  </div>
`;
```

## Server Rendering Behavior

Both React on Rails server rendering and client rendering output web component tags the same way — as plain HTML elements with attributes. The key points:

1. **Tags are in the initial HTML.** The server response includes `<app-greeting name="Alice"></app-greeting>`.
2. **Shadow DOM content is not in the server HTML.** The `connectedCallback` that builds the shadow tree only runs client-side.
3. **Slotted content IS in the server HTML.** Children inside the tags (including named slots) are part of the light DOM and render immediately.
4. **Attributes are preserved.** String attributes set in JSX appear as HTML attributes in the server output.
5. **Object/function props are dropped during SSR.** React's server renderer only serializes primitive attribute values. Non-primitive props are set client-side as properties after hydration.

> [!NOTE]
> The browser standard for server-rendering shadow DOM content is [Declarative Shadow DOM](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_shadow_DOM#declarative_shadow_dom) (`<template shadowrootmode="open">`). React does not support emitting or hydrating Declarative Shadow DOM. This is a React limitation, not a React on Rails limitation. Web component shadow content is always created client-side.

## Avoiding Flash of Unstyled Content (FOUC)

Since shadow DOM content only appears after JavaScript loads, users may see a brief flash of empty or unstyled custom elements. Mitigation strategies:

**Hide undefined elements with CSS:**

```css
:not(:defined) {
  visibility: hidden;
}
```

The `:defined` pseudo-class matches elements that have been registered with `customElements.define()`. Unregistered elements are hidden until their class loads.

**Use slotted content for critical text:**

Place important visible content in slots rather than inside shadow DOM. Slotted content is in the server HTML and visible before JavaScript loads:

```tsx
<app-card>
  <h2 slot="title">Product Name</h2>
  <p>This text is visible immediately from SSR.</p>
</app-card>
```

## Testing with Playwright

Playwright's built-in selector engine pierces **open** shadow DOM automatically when using `page.locator()`. This is a Playwright feature — native `document.querySelector()` does not cross shadow boundaries.

For **closed** shadow DOM, Playwright cannot pierce it either. Expose public methods on your element class and use `page.evaluate()`:

```javascript
// Open shadow — Playwright's selector engine pierces open shadow roots:
await expect(page.locator('.shadow-inner-class')).toBeVisible();

// Closed shadow — use public API methods via page.evaluate():
await page.evaluate(() => {
  const el = document.querySelector('my-closed-component');
  el.reset();
});
const count = await page.evaluate(() => {
  return document.querySelector('my-closed-component').getCount();
});
expect(count).toBe(0);
```
