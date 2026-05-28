# React on Rails Pro: Introducing React Server Components & SSR Streaming

**Subject: 🚀 Revolutionary Performance Boost: React Server Components & SSR Streaming Now Available in React on Rails Pro**

---

Dear Valued React on Rails Pro Client,

We're thrilled to announce a major update: React on Rails Pro now supports **React Server Components** and **Server‑Side Rendering (SSR) Streaming**. These features have driven significant performance gains in real‑world applications—here’s how they can transform yours.

## 🎯 What This Means for Your Applications

- **Faster load times**
- **Smaller JavaScript bundles**
- **Better Core Web Vitals**
- **Improved SEO**
- **Smoother user interactions**

## 🔥 React Server Components

Server Components execute on the server and stream HTML to the client—no extra JavaScript in your bundle. Real‑world results include:

- **62% reduction** in client‑side bundle size on productonboarding.com when migrating to RSC [[1]]
- **63% improvement** in Google Speed Index on the RSC version of the same site [[1]]
- **52% smaller** JavaScript codebase and Lighthouse scores rising from \~50 to 90+ on GeekyAnts.com [[2]]

## 🌊 SSR Streaming

SSR Streaming sends HTML to the browser in chunks as it’s generated, enabling progressive rendering:

- **30% faster** full‑page load times at Hulu by combining streaming SSR with Server Components [[3]]
- Popular libraries like styled‑components v3.1.0 have introduced streaming SSR support as the next generation of React app rendering [[4]]

## 📊 Core Web Vitals & TTI Improvements

- **60% faster** Time to Interactive on Meta’s developer portal after adopting RSC (from 3.5 s to \~1.4 s) [[5]]
- **45% quicker** First Contentful Paint in the same migration [[5]]
- **50% lower** server response time with Server Components [[5]]
- **15% improvement** in Core Web Vitals and **23% reduction** in Time to First Byte at Airbnb after RSC migration [[5]]

> **React on Rails note:** These performance benefits carry over to React on Rails Pro. In React on Rails, data delivery is prop-based — Rails controllers handle database queries, authentication, and caching, then pass data to components as props via [`stream_react_component`](../../oss/migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro). Components do not fetch data directly. See [RSC Migration: Data Fetching Patterns](../../oss/migrating/rsc-data-fetching.md).

---

Adopting these features in React on Rails Pro will help you deliver faster, leaner, and more SEO‑friendly applications with fewer client‑side resources.

**Ready to get started?**

1. Update to the latest React on Rails Pro version
2. Follow our [RSC & SSR Streaming migration guide](../react-server-components/tutorial.md)

Let’s make your apps faster—together.

---

## 📚 References

1. productonboarding.com experiment: 62% bundle reduction, 63% Speed Index gain ([frigade.com][1])
2. GeekyAnts.com case study: 52% code reduction, Lighthouse 50→90+ ([geekyants.com][2])
3. Hulu—30% faster full‑page loads with streaming SSR + RSC ([questlab.pro][3])
4. styled‑components v3.1.0: introduced streaming SSR support as the next generation of React rendering. ([medium.com][4])
5. QuestLab: Meta’s RSC migration—30% JS reduction, 60% faster TTI, 45% faster FCP, 50% lower server response ([questlab.pro][5])

[1]: https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade
[2]: https://geekyants.com/en-gb/blog/boosting-performance-with-nextjs-and-react-server-components-a-geekyantscom-case-study
[3]: https://www.compilenrun.com/docs/framework/nextjs/nextjs-ecosystem/nextjs-case-studies/#case-study-3-hulus-streaming-platform
[4]: https://medium.com/styled-components/v3-1-0-such-perf-wow-many-streams-c45c434dbd03
[5]: https://web.archive.org/web/20250908030148/https://questlab.pro/blog-posts/web-development/wd-pl-2024-articleId912i1h212818
