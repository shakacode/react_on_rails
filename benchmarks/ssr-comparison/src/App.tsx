import React from 'react';
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
import { products, reviews, comments, comparisonData, navItems, breadcrumbs, faqItems, tabData } from './data';

export default function App() {
  return (
    <div className="app-root">
      <NavigationBar items={navItems} />
      <HeroSection />
      <div className="main-layout">
        <Breadcrumb items={breadcrumbs} />
        <div className="content-with-sidebar">
          <Sidebar />
          <main className="main-content">
            <ProductGrid products={products} />
            <TabPanel tabs={tabData} />
            <DataSection columns={comparisonData.columns} rows={comparisonData.rows} />
            <ReviewsList reviews={reviews} />
            <CommentSection comments={comments} />
            <AccordionSection items={faqItems} />
            <PaginationBar currentPage={3} totalPages={12} />
          </main>
        </div>
      </div>
      <Footer />
    </div>
  );
}
