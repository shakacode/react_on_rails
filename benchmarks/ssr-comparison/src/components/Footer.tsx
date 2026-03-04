import React from 'react';

const footerLinks = [
  { heading: 'Shop', links: ['All Products', 'New Arrivals', 'Best Sellers', 'Deals', 'Gift Cards'] },
  { heading: 'Company', links: ['About Us', 'Careers', 'Press', 'Blog', 'Investors'] },
  { heading: 'Support', links: ['Help Center', 'Contact Us', 'Shipping Info', 'Returns', 'Warranty'] },
  { heading: 'Legal', links: ['Privacy Policy', 'Terms of Service', 'Cookie Policy', 'Accessibility', 'DMCA'] },
];

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-main">
        {footerLinks.map((section) => (
          <div key={section.heading} className="footer-column">
            <h4 className="footer-heading">{section.heading}</h4>
            <ul className="footer-links">
              {section.links.map((link) => (
                <li key={link}>
                  <a href={`/${link.toLowerCase().replace(/\s+/g, '-')}`}>{link}</a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="footer-bottom">
        <p className="footer-copyright">&copy; 2025 TechStore. All rights reserved.</p>
        <div className="footer-social">
          <a href="/social/twitter" aria-label="Twitter">Twitter</a>
          <a href="/social/github" aria-label="GitHub">GitHub</a>
          <a href="/social/linkedin" aria-label="LinkedIn">LinkedIn</a>
        </div>
      </div>
    </footer>
  );
}
