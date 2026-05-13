#!/usr/bin/env node
// Generates a ~50MB JS module with embedded data that the LeakRepro component imports.
// Run: node generate-leak-data.js
// Output: LeakReproLargeData.js

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const TARGET_MB = 50;
const OUTPUT = path.join(__dirname, 'LeakReproLargeData.js');

function randomHex(len) {
  return crypto.randomBytes(len).toString('hex');
}

function generateSvgPath(seed) {
  const rng = (s) => {
    s = (s * 16807) % 2147483647;
    return s;
  };
  let s = seed;
  const points = [];
  for (let i = 0; i < 20; i++) {
    s = rng(s);
    const x = (s % 1000) / 10;
    s = rng(s);
    const y = (s % 1000) / 10;
    points.push(i === 0 ? `M${x},${y}` : `C${x},${y} ${x + 5},${y + 5} ${x + 10},${y}`);
  }
  return points.join(' ');
}

let out = '';
out += '// Auto-generated file — do not edit. Run generate-leak-data.js to regenerate.\n';
out += '// This file provides large lookup data used by the LeakRepro component to\n';
out += '// produce a realistically-sized webpack bundle for memory leak measurement.\n\n';

// 1. Large icon library — ~10MB of SVG path data
out += 'export const ICON_LIBRARY = {\n';
const iconCount = 15000;
for (let i = 0; i < iconCount; i++) {
  const name = `icon_${String(i).padStart(5, '0')}_${randomHex(8)}`;
  const svgPath = generateSvgPath(i + 1);
  const viewBox = `0 0 ${100 + (i % 200)} ${100 + (i % 200)}`;
  out += `  "${name}": { path: "${svgPath}", viewBox: "${viewBox}", tags: ["cat${i % 50}", "set${i % 20}"] },\n`;
}
out += '};\n\n';

// 2. Large i18n dictionary — ~10MB of translations
out += 'export const I18N = {\n';
const locales = ['en', 'es', 'fr', 'de', 'ja', 'zh', 'ko', 'pt', 'ru', 'ar', 'hi', 'it', 'nl', 'sv', 'pl'];
for (const locale of locales) {
  out += `  "${locale}": {\n`;
  const entryCount = 2000;
  for (let i = 0; i < entryCount; i++) {
    const key = `msg_${String(i).padStart(4, '0')}`;
    const value = `[${locale}] ${randomHex(40)} — translation entry ${i} for locale ${locale} with padding ${randomHex(20)}`;
    out += `    "${key}": "${value}",\n`;
  }
  out += `  },\n`;
}
out += '};\n\n';

// 3. Large theme system — ~8MB of CSS-like property mappings
out += 'export const THEME_REGISTRY = {\n';
const themeCount = 500;
for (let t = 0; t < themeCount; t++) {
  const themeName = `theme_${String(t).padStart(3, '0')}_${randomHex(4)}`;
  out += `  "${themeName}": {\n`;
  const props = [
    'color',
    'backgroundColor',
    'borderColor',
    'boxShadow',
    'fontFamily',
    'fontSize',
    'fontWeight',
    'lineHeight',
    'letterSpacing',
    'textTransform',
    'padding',
    'margin',
    'borderRadius',
    'opacity',
    'transition',
    'display',
    'flexDirection',
    'alignItems',
    'justifyContent',
    'gap',
  ];
  const components = [
    'header',
    'card',
    'button',
    'input',
    'label',
    'badge',
    'avatar',
    'tooltip',
    'modal',
    'sidebar',
    'nav',
    'footer',
    'table',
    'list',
    'form',
  ];
  for (const comp of components) {
    out += `    "${comp}": { `;
    for (const prop of props) {
      out += `"${prop}": "${randomHex(12)}", `;
    }
    out += `},\n`;
  }
  out += `  },\n`;
}
out += '};\n\n';

// 4. Large base64-encoded font/image placeholder data — fill remaining to reach target
const currentSizeMB = Buffer.byteLength(out, 'utf8') / (1024 * 1024);
const remainingMB = TARGET_MB - currentSizeMB;

if (remainingMB > 0) {
  const chunkSizeMB = 5;
  const chunks = Math.ceil(remainingMB / chunkSizeMB);
  out += 'export const ASSET_DATA = [\n';
  for (let c = 0; c < chunks; c++) {
    const bytes = Math.min(chunkSizeMB, remainingMB - c * chunkSizeMB) * 1024 * 1024 * 0.75; // base64 is ~4/3 of raw
    const buf = crypto.randomBytes(Math.floor(bytes));
    out += `  "${buf.toString('base64')}",\n`;
  }
  out += '];\n\n';
}

// 5. Export a function the component calls to ensure webpack doesn't tree-shake
out += `export function getIconPath(name) {
  return ICON_LIBRARY[name]?.path || ICON_LIBRARY.icon_00000_${randomHex(8)}?.path || '';
}

export function translate(locale, key) {
  return (I18N[locale] && I18N[locale][key]) || I18N.en?.[key] || key;
}

export function getThemeValue(theme, component, prop) {
  return THEME_REGISTRY[theme]?.[component]?.[prop] || '';
}

export function getAssetChunk(index) {
  return ASSET_DATA[index % ASSET_DATA.length] || '';
}

export const DATA_VERSION = "${randomHex(16)}";
export const TOTAL_ICONS = ${iconCount};
export const TOTAL_THEMES = ${themeCount};
export const TOTAL_LOCALES = ${locales.length};
`;

fs.writeFileSync(OUTPUT, out, 'utf8');
const finalSize = fs.statSync(OUTPUT).size;
console.log(`Generated ${OUTPUT}`);
console.log(`Size: ${(finalSize / (1024 * 1024)).toFixed(1)} MB`);
