import React from 'react';
import NavigationBar from './components/NavigationBar';
import HeroSection from './components/HeroSection';
import Breadcrumb from './components/Breadcrumb';
import Sidebar from './components/Sidebar';
import ProductGridLite from './components/ProductGridLite';
import ReviewsListLite from './components/ReviewsListLite';
import DataSectionLite from './components/DataSectionLite';
import CommentSectionLite from './components/CommentSectionLite';
import TabPanel from './components/TabPanel';
import AccordionSection from './components/AccordionSection';
import PaginationBar from './components/PaginationBar';
import Footer from './components/Footer';
import { products, reviews, comments, comparisonData, navItems, breadcrumbs, faqItems, tabData } from './data';

/**
 * Optimized App using lite components:
 * - ProductCardLite: 7 elements instead of ~28 (consolidated stars, specs as text)
 * - ReviewItemLite: ~7 elements instead of ~17 (single star span, flat body)
 * - CommentThreadLite: ~4 elements instead of ~8 (flat header, no collapse UI)
 * - DataSectionLite: dangerouslySetInnerHTML for table body (~1 write instead of ~200)
 *
 * Estimated: ~40% fewer DOM elements than the original App.
 */
export default function AppOptimized() {
  return (
    <div className="app-root">
      <NavigationBar items={navItems} />
      <HeroSection />
      <div className="main-layout">
        <Breadcrumb items={breadcrumbs} />
        <div className="content-with-sidebar">
          <Sidebar />
          <main className="main-content">
            <ProductGridLite products={products} />
            <TabPanel tabs={tabData} />
            <DataSectionLite columns={comparisonData.columns} rows={comparisonData.rows} />
            <ReviewsListLite reviews={reviews} />
            <CommentSectionLite comments={comments} />
            <AccordionSection items={faqItems} />
            <PaginationBar currentPage={3} totalPages={12} />
          </main>
        </div>
      </div>
      <Footer />
    </div>
  );
}
