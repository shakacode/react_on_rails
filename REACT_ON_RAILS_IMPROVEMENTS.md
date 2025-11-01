# React on Rails Incremental Improvements Roadmap

## Practical Baby Steps to Match and Exceed Inertia Rails and Vite Ruby

## Executive Summary

With Rspack integration coming for better build performance and enhanced React Server Components support with a separate node rendering process, React on Rails is well-positioned for incremental improvements. This document outlines practical, achievable baby steps that can be implemented progressively to make React on Rails the clear choice over competitors.

## Current State Analysis

### What We're Building On

- **Rspack Integration** (Coming Soon): Will provide faster builds comparable to Vite
- **React Server Components** (Coming Soon): Separate node rendering process for better RSC support
- **Existing Strengths**: Mature SSR, production-tested, comprehensive features

### Key Gaps to Address Incrementally

- Error messages need improvement
- Setup process could be smoother
- Missing TypeScript-first approach
- No automatic props serialization like Inertia
- Limited debugging tools for RSC

## Incremental Improvement Plan

## Phase 1: Immediate Fixes (Week 1-2)

_Quick wins that improve developer experience immediately_

### 1.1 Better Error Messages

**Effort**: 2-3 days
**Impact**: High

```ruby
# Current: Generic error
"Component HelloWorld not found"

# Improved: Actionable error
"Component 'HelloWorld' not registered. Did you mean 'HelloWorldComponent'?
To register: ReactOnRails.register({ HelloWorld: HelloWorld })
Location: app/javascript/bundles/HelloWorld/components/HelloWorld.jsx"
```

**Implementation**:

- Enhance error messages in `helper.rb`
- Add suggestions for common mistakes
- Include file paths and registration examples

### 1.2 Enhanced Doctor Command

**Effort**: 1-2 days
**Impact**: High

```bash
$ rake react_on_rails:doctor

React on Rails Health Check v16.0
================================
✅ Node version: 18.17.0 (recommended)
✅ Rails version: 7.1.0 (compatible)
⚠️  Shakapacker: 7.0.0 (Rspack migration available)
✅ React version: 18.2.0
⚠️  TypeScript: Not detected (run: rails g react_on_rails:typescript)
❌ Component registration: 2 components not registered on client

Recommendations:
1. Consider migrating to Rspack for 3x faster builds
2. Enable TypeScript for better type safety
3. Check components: ProductList, UserProfile
```

**Implementation**:

- Extend existing doctor command
- Add version compatibility checks
- Provide actionable recommendations

### 1.3 Component Registration Debugging

**Effort**: 1 day  
**Impact**: Medium

```javascript
// Add debug mode
ReactOnRails.configure({
  debugMode: true,
  logComponentRegistration: true,
});

// Console output:
// [ReactOnRails] Registered: HelloWorld (2.3kb)
// [ReactOnRails] Warning: ProductList registered on server but not client
// [ReactOnRails] All components registered in 45ms
```

**Implementation**:

- Add debug logging to ComponentRegistry
- Show bundle sizes and registration timing
- Warn about server/client mismatches

## Phase 2: Developer Experience Polish (Week 3-4)

_Improvements that make daily development smoother_

### 2.1 Modern Generator Templates

**Effort**: 2-3 days
**Impact**: High

```bash
# Current generator creates class components
# Proposed: Modern defaults

$ rails g react_on_rails:component ProductCard

# Detects TypeScript in project and generates:
# app/javascript/components/ProductCard.tsx
import React from 'react'

interface ProductCardProps {
  name: string
  price: number
}

export default function ProductCard({ name, price }: ProductCardProps) {
  return (
    <div className="product-card">
      <h2>{name}</h2>
      <p>${price}</p>
    </div>
  )
}

# Also generates test file if Jest/Vitest detected
```

**Implementation**:

- Update generator templates
- Auto-detect TypeScript, test framework
- Use functional components by default
- Add props interface for TypeScript

### 2.2 Setup Auto-Detection

**Effort**: 2 days
**Impact**: Medium

```ruby
# Proposed: Smart configuration
$ rails g react_on_rails:install

Detecting your setup...
✅ Found: TypeScript configuration
✅ Found: Tailwind CSS
✅ Found: Jest testing
✅ Found: ESLint + Prettier

Configuring React on Rails for your stack...
- Using TypeScript templates
- Configuring Tailwind integration
- Setting up Jest helpers
- Respecting existing ESLint rules
```

**Implementation**:

- Check for common config files
- Adapt templates based on detection
- Preserve existing configurations

### 2.3 Configuration Simplification

**Effort**: 1 day
**Impact**: Medium

```ruby
# Current: Many options, unclear defaults
# Proposed: Simplified with clear comments

ReactOnRails.configure do |config|
  # Rspack optimized defaults (coming soon)
  config.build_system = :rspack # auto-detected

  # Server-side rendering
  config.server_bundle_js_file = "server-bundle.js"
  config.prerender = true # Enable SSR

  # Development experience
  config.development_mode = Rails.env.development?
  config.trace = true # Show render traces in development

  # React Server Components (when using Pro)
  # config.rsc_bundle_js_file = "rsc-bundle.js"
end
```

**Implementation**:

- Simplify configuration file
- Add helpful comments
- Group related settings
- Provide sensible defaults

## Phase 3: Rspack Integration Excellence (Week 5-6)

_Maximize the benefits of upcoming Rspack support_

### 3.1 Rspack Migration Assistant

**Effort**: 3 days
**Impact**: High

```bash
$ rails react_on_rails:migrate_to_rspack

Analyzing your Webpack/Shakapacker configuration...
✅ Standard loaders detected - compatible
⚠️  Custom plugin detected: BundleAnalyzer - needs manual migration
✅ Entry points will migrate automatically

Generated Rspack configuration at: config/rspack.config.js
- Migrated all standard loaders
- Preserved your entry points
- Optimized for React development

Next steps:
1. Review config/rspack.config.js
2. Test with: bin/rspack
3. Run full test suite
```

**Implementation**:

- Parse existing webpack config
- Generate equivalent Rspack config
- Identify manual migration needs
- Provide migration guide

### 3.2 Build Performance Dashboard

**Effort**: 2 days
**Impact**: Medium

```bash
$ rails react_on_rails:perf

Build Performance Comparison:
============================
                Before (Webpack)  After (Rspack)  Improvement
Initial build:       8.2s            2.1s          74% faster
Rebuild (HMR):       1.3s            0.3s          77% faster
Production build:    45s             12s           73% faster
Bundle size:         1.2MB           1.1MB         8% smaller

Top bottlenecks:
1. Large dependency: moment.js (230kb) - Consider date-fns
2. Duplicate React versions detected
3. Source maps adding 400ms to builds
```

**Implementation**:

- Add build timing collection
- Compare before/after metrics
- Identify optimization opportunities
- Store historical data

### 3.3 Rspack-Specific Optimizations

**Effort**: 2 days
**Impact**: Medium

```javascript
// config/rspack.config.js
module.exports = {
  // React on Rails optimized Rspack config
  experiments: {
    rspackFuture: {
      newTreeshaking: true, // Better tree shaking for React
    },
  },
  optimization: {
    moduleIds: 'deterministic', // Consistent builds
    splitChunks: {
      // React on Rails optimal chunking
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          priority: 10,
        },
        react: {
          test: /[\\/]node_modules[\\/](react|react-dom)[\\/]/,
          name: 'react',
          priority: 20,
        },
      },
    },
  },
};
```

**Implementation**:

- Create optimized Rspack presets
- Add React-specific optimizations
- Configure optimal chunking strategy

## Phase 4: React Server Components Polish (Week 7-8)

_Enhance the upcoming RSC support_

### 4.1 RSC Debugging Tools

**Effort**: 3 days
**Impact**: High

```bash
$ rails react_on_rails:rsc:debug

RSC Rendering Pipeline:
======================
1. Request received: /products/123
2. RSC Bundle loaded: rsc-bundle.js (45ms)
3. Component tree:
   <ProductLayout> (RSC)
     <ProductDetails> (RSC)
       <AddToCartButton> (Client) ✅ Hydrated
4. Serialization time: 23ms
5. Total RSC time: 89ms

Warnings:
- Large prop detected in ProductDetails (2MB)
- Consider moving data fetching to RSC component
```

**Implementation**:

- Add RSC render pipeline logging
- Track component boundaries
- Measure serialization time
- Identify optimization opportunities

### 4.2 RSC Component Generator

**Effort**: 2 days
**Impact**: Medium

```bash
$ rails g react_on_rails:rsc ProductView

# Generates:
# app/javascript/components/ProductView.server.tsx
export default async function ProductView({ id }: { id: string }) {
  // This runs on the server only
  const product = await db.products.find(id)

  return (
    <div>
      <h1>{product.name}</h1>
      <ProductClient product={product} />
    </div>
  )
}

# app/javascript/components/ProductClient.client.tsx
'use client'
export default function ProductClient({ product }) {
  // Interactive client component
}
```

**Implementation**:

- Add RSC-specific generators
- Use .server and .client conventions
- Include async data fetching examples

### 4.3 RSC Performance Monitor

**Effort**: 2 days
**Impact**: Medium

```ruby
# Add to development middleware
class RSCPerformanceMiddleware
  def call(env)
    if rsc_request?(env)
      start = Time.now
      result = @app.call(env)
      duration = Time.now - start

      Rails.logger.info "[RSC] Rendered in #{duration}ms"
      result
    else
      @app.call(env)
    end
  end
end
```

**Implementation**:

- Add timing middleware
- Track RSC vs traditional renders
- Log performance metrics

## Phase 5: Competitive Feature Parity (Week 9-10)

_Add key features that competitors offer_

### 5.1 Inertia-Style Controller Helpers

**Effort**: 3 days
**Impact**: High

```ruby
# Simple props passing like Inertia
class ProductsController < ApplicationController
  include ReactOnRails::ControllerHelpers

  def show
    @product = Product.find(params[:id])
    @reviews = @product.reviews.recent

    # Automatically serializes instance variables as props
    render_component "ProductShow"
    # Props: { product: @product, reviews: @reviews }
  end

  def index
    @products = Product.page(params[:page])

    # With explicit props
    render_component "ProductList", props: {
      products: @products,
      total: @products.total_count
    }
  end
end
```

**Implementation**:

- Create ControllerHelpers module
- Auto-serialize instance variables
- Support explicit props override
- Handle pagination metadata

### 5.2 TypeScript Model Generation

**Effort**: 3 days
**Impact**: High

```bash
$ rails react_on_rails:types:generate

# Analyzes Active Record models and generates:
# app/javascript/types/models.d.ts

export interface User {
  id: number
  email: string
  name: string
  createdAt: string
  updatedAt: string
}

export interface Product {
  id: number
  name: string
  price: number
  description: string | null
  user: User
  reviews: Review[]
}

# Also generates API types from serializers if present
```

**Implementation**:

- Parse Active Record models
- Generate TypeScript interfaces
- Handle associations
- Support nullable fields

### 5.3 Form Component Helpers

**Effort**: 2 days
**Impact**: Medium

```tsx
// Simple Rails-integrated forms
import { useRailsForm } from 'react-on-rails/forms';

export default function ProductForm({ product }) {
  const { form, submit, errors } = useRailsForm({
    action: '/products',
    method: 'POST',
    model: product,
  });

  return (
    <form onSubmit={submit}>
      <input {...form.register('name')} />
      {errors.name && <span>{errors.name}</span>}

      <input {...form.register('price')} type="number" />
      {errors.price && <span>{errors.price}</span>}

      <button type="submit">Save Product</button>
    </form>
  );
}
```

**Implementation**:

- Create form hooks
- Handle CSRF tokens automatically
- Integrate with Rails validations
- Support error display

## Phase 6: Documentation & Onboarding (Week 11-12)

_Make it easier to learn and adopt_

### 6.1 Interactive Setup Wizard

**Effort**: 3 days
**Impact**: High

```bash
$ rails react_on_rails:setup

Welcome to React on Rails Setup Wizard! 🚀

What would you like to set up?
[x] TypeScript support
[x] Testing with Jest
[ ] Storybook
[x] Tailwind CSS
[ ] Redux

Build system:
○ Shakapacker (current)
● Rspack (recommended - 3x faster)
○ Keep existing

Server-side rendering:
● Yes, enable SSR
○ No, client-side only

Generating configuration...
✅ TypeScript configured
✅ Jest test helpers added
✅ Tailwind CSS integrated
✅ Rspack configured
✅ SSR enabled

Run 'bin/dev' to start developing!
```

**Implementation**:

- Create interactive CLI wizard
- Guide through common options
- Generate appropriate config
- Provide next steps

### 6.2 Migration Tool from Inertia

**Effort**: 4 days
**Impact**: High

```bash
$ rails react_on_rails:migrate:from_inertia

Analyzing Inertia setup...
Found: 23 Inertia components
Found: 45 controller actions using Inertia

Migration plan:
1. ✅ Can auto-migrate: 20 components (simple props)
2. ⚠️  Need review: 3 components (use Inertia.visit)
3. 📝 Controller updates: Add render_component calls

Proceed with migration? (y/n) y

Migrating components...
✅ Converted UserProfile.jsx
✅ Converted ProductList.jsx
⚠️  Manual review needed: Navigation.jsx (uses Inertia router)

Generated migration guide at: MIGRATION_GUIDE.md
```

**Implementation**:

- Parse Inertia components
- Convert to React on Rails format
- Update controller rendering
- Generate migration guide

### 6.3 Component Catalog Generator

**Effort**: 2 days
**Impact**: Medium

```bash
$ rails react_on_rails:catalog

Generating component catalog...
Found 34 components

Starting catalog server at http://localhost:3030

Component Catalog:
├── Forms (5)
│   ├── LoginForm
│   ├── RegisterForm
│   └── ProductForm
├── Layout (8)
│   ├── Header
│   ├── Footer
│   └── Sidebar
└── Products (12)
    ├── ProductCard
    ├── ProductList
    └── ProductDetails

Each component shows:
- Live preview
- Props documentation
- Usage examples
- Performance metrics
```

**Implementation**:

- Scan for React components
- Generate catalog app
- Extract prop types
- Create live playground

## Phase 7: Performance Optimizations (Week 13-14)

_Small improvements with big impact_

### 7.1 Automatic Component Preloading

**Effort**: 2 days
**Impact**: Medium

```ruby
# Automatically preload components based on routes
class ApplicationController < ActionController::Base
  before_action :preload_components

  def preload_components
    case controller_name
    when 'products'
      preload_react_component('ProductList', 'ProductDetails')
    when 'users'
      preload_react_component('UserProfile', 'UserSettings')
    end
  end
end

# Adds link headers for component chunks
# Link: </packs/ProductList-hash.js>; rel=preload; as=script
```

**Implementation**:

- Add preloading helpers
- Generate Link headers
- Support route-based preloading

### 7.2 Bundle Analysis Command

**Effort**: 1 day
**Impact**: Medium

```bash
$ rails react_on_rails:bundle:analyze

Bundle Analysis:
================
Total size: 524 KB (156 KB gzipped)

Largest modules:
1. react-dom: 128 KB (24.4%)
2. @mui/material: 89 KB (17.0%)
3. lodash: 71 KB (13.5%)
4. Your code: 68 KB (13.0%)

Duplicates detected:
- lodash: Imported by 3 different modules
  Fix: Import from 'lodash-es' instead

Unused exports:
- ProductOldVersion (12 KB)
- DeprecatedHelper (8 KB)

Recommendations:
1. Code-split @mui/material (saves 89 KB initial)
2. Replace lodash with lodash-es (saves 15 KB)
3. Remove unused exports (saves 20 KB)
```

**Implementation**:

- Integrate with webpack-bundle-analyzer
- Parse bundle stats
- Identify optimization opportunities

### 7.3 Lazy Loading Helpers

**Effort**: 2 days
**Impact**: Medium

```tsx
// Simplified lazy loading with React on Rails
import { lazyComponent } from 'react-on-rails/lazy'

// Automatically handles loading states and errors
const ProductDetails = lazyComponent(() => import('./ProductDetails'), {
  fallback: <ProductSkeleton />,
  errorBoundary: true,
  preload: 'hover', // Preload on hover
  timeout: 5000
})

// In Rails view:
<%= react_component_lazy("ProductDetails",
      props: @product,
      loading: "ProductSkeleton") %>
```

**Implementation**:

- Create lazy loading utilities
- Add loading state handling
- Support preloading strategies
- Integrate with Rails helpers

## Phase 8: Testing Improvements (Week 15-16)

_Make testing easier and more reliable_

### 8.1 Test Helper Enhancements

**Effort**: 2 days
**Impact**: Medium

```ruby
# Enhanced RSpec helpers
RSpec.describe "Product page", type: :react do
  include ReactOnRails::TestHelpers

  let(:product) { create(:product, name: "iPhone", price: 999) }

  it "renders product information" do
    render_component("ProductCard", props: { product: product })

    # New helpers
    expect(component).to have_react_text("iPhone")
    expect(component).to have_react_prop(:price, 999)
    expect(component).to have_react_class("product-card")

    # Interaction helpers
    click_react_button("Add to Cart")
    expect(component).to have_react_state(:cartCount, 1)
  end
end
```

**Implementation**:

- Extend test helpers
- Add React-specific matchers
- Support interaction testing
- Improve error messages

### 8.2 Component Test Generator

**Effort**: 1 day
**Impact**: Low

```bash
$ rails g react_on_rails:test ProductCard

# Generates test based on component props
# spec/javascript/components/ProductCard.spec.tsx

import { render, screen } from '@testing-library/react'
import ProductCard from 'components/ProductCard'

describe('ProductCard', () => {
  const defaultProps = {
    name: 'Test Product',
    price: 99.99
  }

  it('renders product name', () => {
    render(<ProductCard {...defaultProps} />)
    expect(screen.getByText('Test Product')).toBeInTheDocument()
  })

  it('renders price', () => {
    render(<ProductCard {...defaultProps} />)
    expect(screen.getByText('$99.99')).toBeInTheDocument()
  })
})
```

**Implementation**:

- Parse component props
- Generate appropriate tests
- Use detected test framework
- Include common test cases

## Implementation Priority Matrix

| Priority       | Effort | Impact | Items                                                       |
| -------------- | ------ | ------ | ----------------------------------------------------------- |
| **Do First**   | Low    | High   | Better error messages, Enhanced doctor, Modern generators   |
| **Do Next**    | Medium | High   | Rspack migration, Controller helpers, TypeScript generation |
| **Quick Wins** | Low    | Medium | Config simplification, Debug logging, Test generators       |
| **Long Game**  | High   | High   | Interactive wizard, Migration tools, Component catalog      |

## Success Metrics

### Short Term (4 weeks)

- **Setup time**: Reduce from 30 min to 10 min
- **Error clarity**: 90% of errors have actionable solutions
- **Build speed**: 3x faster with Rspack

### Medium Term (8 weeks)

- **TypeScript adoption**: 50% of new projects use TypeScript
- **Migration success**: 10+ projects migrated from Inertia
- **RSC usage**: 25% of Pro users adopt RSC

### Long Term (16 weeks)

- **Developer satisfaction**: 4.5+ rating
- **Community growth**: 20% increase in contributors
- **Production adoption**: 50+ new production deployments

## Conclusion

These incremental improvements focus on:

1. **Immediate pain relief** through better errors and debugging
2. **Building on strengths** with Rspack and RSC enhancements
3. **Matching competitor features** with practical implementations
4. **Progressive enhancement** without breaking changes

Each improvement is:

- **Independently valuable**
- **Backwards compatible**
- **Achievable in days/weeks**
- **Building toward competitive advantage**

The key is starting with high-impact, low-effort improvements while building toward feature parity with competitors. With Rspack and enhanced RSC support as a foundation, these incremental improvements will position React on Rails as the superior choice for React/Rails integration.
