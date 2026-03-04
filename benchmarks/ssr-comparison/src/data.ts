export interface Product {
  id: number;
  name: string;
  price: number;
  rating: number;
  description: string;
  image: string;
  specs: Record<string, string>;
}

export interface Review {
  id: number;
  author: string;
  date: string;
  stars: number;
  title: string;
  body: string;
}

export interface Comment {
  id: number;
  author: string;
  date: string;
  text: string;
  replies: Comment[];
}

export interface NavItem {
  label: string;
  href: string;
  children?: NavItem[];
}

export interface FAQItem {
  question: string;
  answer: string;
}

export interface DataRow {
  [key: string]: string | number;
}

const productNames = [
  'Ultra HD Monitor 27"', 'Mechanical Keyboard Pro', 'Wireless Gaming Mouse', 'USB-C Docking Station',
  'Noise Cancelling Headphones', 'Portable SSD 2TB', 'Webcam 4K HDR', 'Ergonomic Office Chair',
  'Standing Desk Converter', 'LED Desk Lamp Pro', 'Thunderbolt Cable 2m', 'Laptop Stand Aluminum',
  'Bluetooth Speaker Mini', 'Wireless Charging Pad', 'Smart Power Strip', 'Cable Management Kit',
  'Monitor Light Bar', 'Keyboard Wrist Rest', 'Mouse Pad XXL', 'Screen Privacy Filter',
  'USB Hub 7-Port', 'Ethernet Adapter', 'HDMI Switch 4K', 'Desk Organizer Set',
];

export const products: Product[] = productNames.map((name, i) => ({
  id: i + 1,
  name,
  price: Math.round((19.99 + i * 12.5) * 100) / 100,
  rating: 3 + (i % 3),
  description: `High-quality ${name.toLowerCase()} designed for professionals and enthusiasts. Features premium build quality, extensive compatibility, and a ${i + 1}-year warranty. This product has been tested across multiple environments to ensure reliability and performance in demanding workflows.`,
  image: `/images/product-${i + 1}.jpg`,
  specs: {
    Weight: `${(0.2 + i * 0.15).toFixed(1)} kg`,
    Dimensions: `${10 + i * 2}x${8 + i}x${3 + i * 0.5} cm`,
    Color: ['Black', 'Silver', 'White', 'Space Gray'][i % 4],
    Warranty: `${(i % 3) + 1} years`,
    Material: ['Aluminum', 'ABS Plastic', 'Steel', 'Carbon Fiber'][i % 4],
  },
}));

export const reviews: Review[] = Array.from({ length: 15 }, (_, i) => ({
  id: i + 1,
  author: ['Alice Johnson', 'Bob Smith', 'Carol White', 'David Brown', 'Eva Martinez'][i % 5],
  date: `2025-${String((i % 12) + 1).padStart(2, '0')}-${String((i % 28) + 1).padStart(2, '0')}`,
  stars: 3 + (i % 3),
  title: [
    'Excellent quality and fast shipping',
    'Good value for the price',
    'Exactly what I needed',
    'Solid build, minor issues',
    'Outstanding product experience',
  ][i % 5],
  body: `I've been using this product for ${i + 1} weeks now and I'm ${['very impressed', 'quite satisfied', 'generally happy'][i % 3]} with it. ` +
    `The build quality is ${['exceptional', 'solid', 'decent'][i % 3]} and it integrates well with my existing setup. ` +
    `Setup was ${['effortless', 'straightforward', 'a bit tricky but manageable'][i % 3]} — took about ${(i % 3) + 1} minutes. ` +
    `\n\nCompared to the ${['previous model', 'competition', 'alternatives'][i % 3]}, this one ${['stands out', 'holds its own', 'is a clear winner'][i % 3]}. ` +
    `The ${['ergonomics', 'performance', 'design'][i % 3]} is particularly noteworthy. ` +
    `I would ${['highly recommend', 'recommend', 'cautiously recommend'][i % 3]} this to anyone looking for a reliable solution in this category.` +
    `\n\nOne thing to note: ${['make sure to update the firmware', 'the manual could be better', 'customer support was helpful'][i % 3]}. Overall, ${i + 3}/5 stars.`,
}));

function makeComments(depth: number, parentId: number, count: number): Comment[] {
  if (depth === 0) return [];
  return Array.from({ length: count }, (_, i) => {
    const id = parentId * 100 + i + 1;
    return {
      id,
      author: ['User_Alpha', 'User_Beta', 'User_Gamma', 'User_Delta', 'User_Epsilon'][i % 5],
      date: `2025-03-${String((i % 28) + 1).padStart(2, '0')}`,
      text: `This is a ${['thoughtful', 'detailed', 'brief', 'insightful', 'practical'][i % 5]} comment at depth ${3 - depth + 1}. ` +
        `I ${['agree with', 'partially disagree with', 'want to add to', 'have a question about', 'appreciate'][i % 5]} the point above. ` +
        `In my experience, ${['this approach works well', 'there are better alternatives', 'it depends on the context', 'the key factor is consistency', 'documentation is crucial'][i % 5]}.`,
      replies: makeComments(depth - 1, id, Math.min(count - 1, 2)),
    };
  });
}

export const comments: Comment[] = makeComments(3, 0, 10);

const columns = ['Product', 'Q1 Sales', 'Q2 Sales', 'Q3 Sales', 'Q4 Sales', 'Total', 'Growth', 'Rating'];

export const comparisonData: { columns: string[]; rows: DataRow[] } = {
  columns,
  rows: Array.from({ length: 20 }, (_, i) => {
    const q1 = 1000 + i * 250;
    const q2 = 1200 + i * 300;
    const q3 = 900 + i * 200;
    const q4 = 1500 + i * 350;
    return {
      Product: `Product Line ${String.fromCharCode(65 + i)}`,
      'Q1 Sales': q1,
      'Q2 Sales': q2,
      'Q3 Sales': q3,
      'Q4 Sales': q4,
      Total: q1 + q2 + q3 + q4,
      Growth: `${(5 + i * 1.5).toFixed(1)}%`,
      Rating: (3.5 + (i % 10) * 0.15).toFixed(1),
    };
  }),
};

export const navItems: NavItem[] = [
  {
    label: 'Products', href: '/products', children: [
      { label: 'Monitors', href: '/products/monitors', children: [
        { label: 'Gaming', href: '/products/monitors/gaming' },
        { label: 'Professional', href: '/products/monitors/pro' },
      ]},
      { label: 'Peripherals', href: '/products/peripherals', children: [
        { label: 'Keyboards', href: '/products/peripherals/keyboards' },
        { label: 'Mice', href: '/products/peripherals/mice' },
      ]},
      { label: 'Audio', href: '/products/audio' },
    ],
  },
  {
    label: 'Solutions', href: '/solutions', children: [
      { label: 'Home Office', href: '/solutions/home-office' },
      { label: 'Enterprise', href: '/solutions/enterprise' },
      { label: 'Education', href: '/solutions/education' },
    ],
  },
  {
    label: 'Support', href: '/support', children: [
      { label: 'Documentation', href: '/support/docs' },
      { label: 'Community', href: '/support/community' },
      { label: 'Contact', href: '/support/contact' },
    ],
  },
];

export const breadcrumbs = [
  { label: 'Home', href: '/' },
  { label: 'Products', href: '/products' },
  { label: 'Monitors', href: '/products/monitors' },
  { label: 'Ultra HD Monitor 27"', href: '/products/monitors/ultra-hd-27' },
];

export const faqItems: FAQItem[] = [
  { question: 'What is the return policy?', answer: 'We offer a 30-day no-questions-asked return policy for all products. Items must be in original packaging and unused condition. Refunds are processed within 5-7 business days of receiving the return.' },
  { question: 'Do you offer international shipping?', answer: 'Yes, we ship to over 50 countries worldwide. International shipping typically takes 7-14 business days. Customs fees and import duties are the responsibility of the buyer.' },
  { question: 'How do I track my order?', answer: 'Once your order ships, you will receive a tracking number via email. You can use this number on our website or the carrier website to track your package in real-time.' },
  { question: 'What payment methods do you accept?', answer: 'We accept all major credit cards (Visa, Mastercard, Amex), PayPal, Apple Pay, Google Pay, and bank transfers for orders over $500.' },
  { question: 'Is there a warranty on products?', answer: 'All products come with a manufacturer warranty ranging from 1 to 3 years depending on the product category. Extended warranty options are available at checkout.' },
  { question: 'Can I cancel or modify my order?', answer: 'Orders can be cancelled or modified within 2 hours of placement. After that, the order enters processing and changes may not be possible. Contact support for assistance.' },
  { question: 'Do you offer bulk discounts?', answer: 'Yes, we offer tiered pricing for bulk orders. Orders of 10+ units receive 5% off, 25+ units receive 10% off, and 100+ units receive 15% off. Contact our sales team for custom quotes.' },
  { question: 'How do I contact customer support?', answer: 'You can reach us via email at support@example.com, live chat on our website (Mon-Fri 9am-6pm EST), or call 1-800-EXAMPLE. Average response time is under 2 hours.' },
];

export const tabData = [
  { id: 'overview', label: 'Overview', content: 'This product represents the pinnacle of engineering in its category. Designed with meticulous attention to detail, it combines form and function to deliver an unparalleled user experience. Our team spent over 18 months refining every aspect, from the materials used to the ergonomic design.' },
  { id: 'specifications', label: 'Specifications', content: 'Dimensions: 450mm x 350mm x 120mm. Weight: 2.4kg. Power consumption: 45W typical, 65W peak. Operating temperature: 0-40C. Connectivity: USB-C 3.2 Gen 2, Thunderbolt 4, WiFi 6E, Bluetooth 5.3. Display: 27-inch IPS, 3840x2160, 165Hz, HDR600.' },
  { id: 'reviews-tab', label: 'Reviews', content: 'Average rating: 4.6 out of 5 stars based on 2,847 verified reviews. 89% of customers would recommend this product. Most praised features: build quality (94%), ease of setup (91%), value for money (87%). Common suggestions: improved documentation (mentioned in 12% of reviews).' },
  { id: 'shipping', label: 'Shipping', content: 'Free standard shipping on orders over $50. Standard shipping: 5-7 business days ($4.99). Express shipping: 2-3 business days ($12.99). Next-day shipping: ($24.99, order by 2pm EST). We ship from warehouses in CA, TX, and NY for fastest delivery.' },
];
