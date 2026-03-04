import React, { Suspense, use } from 'react';
import NavigationBar from './components/NavigationBar';
import HeroSection from './components/HeroSection';
import Breadcrumb from './components/Breadcrumb';
import Sidebar from './components/Sidebar';
import ProductGrid from './components/ProductGrid';
import ReviewsList from './components/ReviewsList';
import DataSection from './components/DataSection';
import CommentSection from './components/CommentSection';
import TabPanel from './components/TabPanel';
import AccordionSection from './components/AccordionSection';
import PaginationBar from './components/PaginationBar';
import Footer from './components/Footer';
import { navItems, breadcrumbs, faqItems, tabData } from './data';
import type { Product, Review, Comment, DataRow } from './data';

// Async wrapper components — use React.use() to read data from promises.
// When the promise is pending, React suspends and renders the fallback.
// When resolved, the real content renders and streams to the client.

function AsyncProductGrid({ promise }: { promise: Promise<Product[]> }) {
  const products = use(promise);
  return <ProductGrid products={products} />;
}

function AsyncReviewsList({ promise }: { promise: Promise<Review[]> }) {
  const reviews = use(promise);
  return <ReviewsList reviews={reviews} />;
}

function AsyncCommentSection({ promise }: { promise: Promise<Comment[]> }) {
  const comments = use(promise);
  return <CommentSection comments={comments} />;
}

function AsyncDataSection({ promise }: { promise: Promise<{ columns: string[]; rows: DataRow[] }> }) {
  const data = use(promise);
  return <DataSection columns={data.columns} rows={data.rows} />;
}

export interface SuspenseAppProps {
  productsPromise: Promise<Product[]>;
  reviewsPromise: Promise<Review[]>;
  commentsPromise: Promise<Comment[]>;
  comparisonDataPromise: Promise<{ columns: string[]; rows: DataRow[] }>;
}

export default function SuspenseApp({
  productsPromise,
  reviewsPromise,
  commentsPromise,
  comparisonDataPromise,
}: SuspenseAppProps) {
  return (
    <div className="app-root">
      <NavigationBar items={navItems} />
      <HeroSection />
      <div className="main-layout">
        <Breadcrumb items={breadcrumbs} />
        <div className="content-with-sidebar">
          <Sidebar />
          <main className="main-content">
            <Suspense fallback={<div className="skeleton product-skeleton">Loading products...</div>}>
              <AsyncProductGrid promise={productsPromise} />
            </Suspense>
            <TabPanel tabs={tabData} />
            <Suspense fallback={<div className="skeleton data-skeleton">Loading data...</div>}>
              <AsyncDataSection promise={comparisonDataPromise} />
            </Suspense>
            <Suspense fallback={<div className="skeleton reviews-skeleton">Loading reviews...</div>}>
              <AsyncReviewsList promise={reviewsPromise} />
            </Suspense>
            <Suspense fallback={<div className="skeleton comments-skeleton">Loading comments...</div>}>
              <AsyncCommentSection promise={commentsPromise} />
            </Suspense>
            <AccordionSection items={faqItems} />
            <PaginationBar currentPage={3} totalPages={12} />
          </main>
        </div>
      </div>
      <Footer />
    </div>
  );
}
