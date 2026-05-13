'use client';

import React from 'react';
import { getIconPath, translate, getThemeValue, getAssetChunk, TOTAL_ICONS, DATA_VERSION } from './LeakReproLargeData';

const COLOR_PALETTE = {
  slate50: '#f8fafc',
  slate100: '#f1f5f9',
  slate200: '#e2e8f0',
  slate300: '#cbd5e1',
  slate400: '#94a3b8',
  slate500: '#64748b',
  slate600: '#475569',
  slate700: '#334155',
  slate800: '#1e293b',
  slate900: '#0f172a',
  red50: '#fef2f2',
  red100: '#fee2e2',
  red200: '#fecaca',
  red300: '#fca5a5',
  red400: '#f87171',
  red500: '#ef4444',
  red600: '#dc2626',
  red700: '#b91c1c',
  blue50: '#eff6ff',
  blue100: '#dbeafe',
  blue200: '#bfdbfe',
  blue300: '#93c5fd',
  blue400: '#60a5fa',
  blue500: '#3b82f6',
  blue600: '#2563eb',
  blue700: '#1d4ed8',
  green50: '#f0fdf4',
  green100: '#dcfce7',
  green200: '#bbf7d0',
  green300: '#86efac',
  green400: '#4ade80',
  green500: '#22c55e',
  green600: '#16a34a',
  green700: '#15803d',
  amber50: '#fffbeb',
  amber100: '#fef3c7',
  amber200: '#fde68a',
  amber300: '#fcd34d',
  amber400: '#fbbf24',
  amber500: '#f59e0b',
  amber600: '#d97706',
  amber700: '#b45309',
  purple50: '#faf5ff',
  purple100: '#f3e8ff',
  purple200: '#e9d5ff',
  purple300: '#d8b4fe',
  purple400: '#c084fc',
  purple500: '#a855f7',
  purple600: '#9333ea',
  purple700: '#7e22ce',
  pink50: '#fdf2f8',
  pink100: '#fce7f3',
  pink200: '#fbcfe8',
  pink300: '#f9a8d4',
  pink400: '#f472b6',
  pink500: '#ec4899',
  pink600: '#db2777',
  pink700: '#be185d',
  teal50: '#f0fdfa',
  teal100: '#ccfbf1',
  teal200: '#99f6e4',
  teal300: '#5eead4',
  teal400: '#2dd4bf',
  teal500: '#14b8a6',
  teal600: '#0d9488',
  teal700: '#0f766e',
  orange50: '#fff7ed',
  orange100: '#ffedd5',
  orange200: '#fed7aa',
  orange300: '#fdba74',
  orange400: '#fb923c',
  orange500: '#f97316',
  orange600: '#ea580c',
  orange700: '#c2410c',
  cyan50: '#ecfeff',
  cyan100: '#cffafe',
  cyan200: '#a5f3fc',
  cyan300: '#67e8f9',
  cyan400: '#22d3ee',
  cyan500: '#06b6d4',
  cyan600: '#0891b2',
  cyan700: '#0e7490',
  indigo50: '#eef2ff',
  indigo100: '#e0e7ff',
  indigo200: '#c7d2fe',
  indigo300: '#a5b4fc',
  indigo400: '#818cf8',
  indigo500: '#6366f1',
  indigo600: '#4f46e5',
  indigo700: '#4338ca',
};

const CATEGORY_ICONS = {
  Technology:
    'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z',
  Science:
    'M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96z',
  Health:
    'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
  Finance:
    'M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z',
  Education: 'M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 9-4.91V17h2V9L12 3z',
  Sports:
    'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zM5.61 16.78C4.6 15.45 4 13.8 4 12s.6-3.45 1.61-4.78',
  Entertainment:
    'M18 3v2h-2V3H8v2H6V3H4v18h2v-2h2v2h8v-2h2v2h2V3h-2zM8 17H6v-2h2v2zm0-4H6v-2h2v2zm0-4H6V7h2v2zm10 8h-2v-2h2v2zm0-4h-2v-2h2v2zm0-4h-2V7h2v2z',
  Travel:
    'M21 16v-2l-8-5V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5l8 2.5z',
  Food: 'M8.1 13.34l2.83-2.83L3.91 3.5c-1.56 1.56-1.56 4.09 0 5.66l4.19 4.18zm6.78-1.81c1.53.71 3.68.21 5.27-1.38 1.91-1.91 2.28-4.65.81-6.12-1.46-1.46-4.2-1.1-6.12.81-1.59 1.59-2.09 3.74-1.38 5.27L3.7 19.87l1.41 1.41L12 14.41l6.88 6.88 1.41-1.41L13.41 13l1.47-1.47z',
  Art: 'M12 22C6.49 22 2 17.51 2 12S6.49 2 12 2s10 4.04 10 9c0 3.31-2.69 6-6 6h-1.77c-.28 0-.5.22-.5.5 0 .12.05.23.13.33.41.47.64 1.06.64 1.67A2.5 2.5 0 0112 22zm0-18c-4.41 0-8 3.59-8 8s3.59 8 8 8c.28 0 .5-.22.5-.5a.54.54 0 00-.14-.35c-.41-.46-.63-1.05-.63-1.65a2.5 2.5 0 012.5-2.5H16c2.21 0 4-1.79 4-4 0-3.86-3.59-7-8-7z',
};

const LOCALE_STRINGS = {
  views: 'Views',
  likes: 'Likes',
  shares: 'Shares',
  bookmarks: 'Bookmarks',
  impressions: 'Impressions',
  clickRate: 'Click Rate',
  comments: 'Comments',
  replies: 'Replies',
  score: 'Score',
  featured: 'Featured',
  priority: 'Priority',
  category: 'Category',
  keywords: 'Keywords',
  dimensions: 'Dimensions',
  address: 'Address',
  metadata: 'Metadata',
  stats: 'Statistics',
  postedBy: 'Posted by',
  updatedOn: 'Updated on',
  createdOn: 'Created on',
  showMore: 'Show more',
  showLess: 'Show less',
  readMore: 'Read more',
  loadMore: 'Load more',
  noResults: 'No results found',
  loading: 'Loading...',
  error: 'An error occurred',
  retry: 'Retry',
  cancel: 'Cancel',
  save: 'Save',
  delete: 'Delete',
  edit: 'Edit',
  share: 'Share',
  bookmark: 'Bookmark',
  report: 'Report',
  block: 'Block',
  mute: 'Mute',
  follow: 'Follow',
  unfollow: 'Unfollow',
  like: 'Like',
  unlike: 'Unlike',
  reply: 'Reply',
  replyTo: 'Reply to',
  quotedReply: 'Quoted reply',
  forward: 'Forward',
  pin: 'Pin',
  unpin: 'Unpin',
  archive: 'Archive',
  unarchive: 'Unarchive',
  markAsRead: 'Mark as read',
  markAsUnread: 'Mark as unread',
  selectAll: 'Select all',
  deselectAll: 'Deselect all',
  sortBy: 'Sort by',
  filterBy: 'Filter by',
  groupBy: 'Group by',
  ascending: 'Ascending',
  descending: 'Descending',
  newest: 'Newest',
  oldest: 'Oldest',
  popular: 'Popular',
  trending: 'Trending',
  relevant: 'Most relevant',
  topRated: 'Top rated',
};

function formatNumber(n) {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return String(n);
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
}

function priorityColor(level) {
  const map = {
    1: COLOR_PALETTE.green500,
    2: COLOR_PALETTE.blue500,
    3: COLOR_PALETTE.amber500,
    4: COLOR_PALETTE.orange500,
    5: COLOR_PALETTE.red500,
  };
  return map[level] || COLOR_PALETTE.slate500;
}

function CategoryIcon({ category, size = 18, color = COLOR_PALETTE.slate600 }) {
  const pathData = CATEGORY_ICONS[category] || CATEGORY_ICONS.Technology;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={color}
      style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: '6px', flexShrink: 0 }}
    >
      <path d={pathData} />
    </svg>
  );
}

function ThumbnailImage({ svg, alt, width = 400, height = 300 }) {
  return (
    <div
      style={{
        width: `${width}px`,
        maxWidth: '100%',
        height: `${height}px`,
        borderRadius: '8px',
        overflow: 'hidden',
        border: `1px solid ${COLOR_PALETTE.slate200}`,
        marginBottom: '12px',
        backgroundColor: COLOR_PALETTE.slate50,
        flexShrink: 0,
      }}
    >
      <div style={{ width: '100%', height: '100%' }} dangerouslySetInnerHTML={{ __html: svg }} />
      <span style={{ position: 'absolute', clip: 'rect(0,0,0,0)', overflow: 'hidden' }}>{alt}</span>
    </div>
  );
}

function StatsBar({ stats }) {
  const entries = [
    { key: 'views', icon: '👁', value: stats.views },
    { key: 'likes', icon: '♥', value: stats.likes },
    { key: 'shares', icon: '↗', value: stats.shares },
    { key: 'bookmarks', icon: '★', value: stats.bookmarks },
    { key: 'impressions', icon: '◉', value: stats.impressions },
  ];
  return (
    <div
      style={{
        display: 'flex',
        flexWrap: 'wrap',
        gap: '16px',
        padding: '10px 0',
        borderTop: `1px solid ${COLOR_PALETTE.slate200}`,
        borderBottom: `1px solid ${COLOR_PALETTE.slate200}`,
        margin: '8px 0',
      }}
    >
      {entries.map((e) => (
        <div
          key={e.key}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            fontSize: '13px',
            color: COLOR_PALETTE.slate600,
          }}
        >
          <span style={{ fontSize: '14px' }}>{e.icon}</span>
          <span style={{ fontWeight: 600 }}>{formatNumber(e.value)}</span>
          <span style={{ color: COLOR_PALETTE.slate400 }}>{LOCALE_STRINGS[e.key]}</span>
        </div>
      ))}
      {stats.clickRate != null && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            fontSize: '13px',
            color: COLOR_PALETTE.slate600,
          }}
        >
          <span style={{ fontWeight: 600 }}>{stats.clickRate}%</span>
          <span style={{ color: COLOR_PALETTE.slate400 }}>{LOCALE_STRINGS.clickRate}</span>
        </div>
      )}
    </div>
  );
}

function TagCloud({ tags }) {
  const tagColors = [
    COLOR_PALETTE.blue100,
    COLOR_PALETTE.green100,
    COLOR_PALETTE.amber100,
    COLOR_PALETTE.purple100,
    COLOR_PALETTE.pink100,
    COLOR_PALETTE.teal100,
    COLOR_PALETTE.orange100,
    COLOR_PALETTE.cyan100,
  ];
  const textColors = [
    COLOR_PALETTE.blue700,
    COLOR_PALETTE.green700,
    COLOR_PALETTE.amber700,
    COLOR_PALETTE.purple700,
    COLOR_PALETTE.pink700,
    COLOR_PALETTE.teal700,
    COLOR_PALETTE.orange700,
    COLOR_PALETTE.cyan700,
  ];
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', margin: '8px 0' }}>
      {tags.map((tag, idx) => (
        <span
          key={tag}
          style={{
            padding: '3px 10px',
            borderRadius: '12px',
            backgroundColor: tagColors[idx % tagColors.length],
            color: textColors[idx % textColors.length],
            fontSize: '12px',
            fontWeight: 500,
            lineHeight: '1.5',
            letterSpacing: '0.02em',
            whiteSpace: 'nowrap',
          }}
        >
          {tag}
        </span>
      ))}
    </div>
  );
}

function AddressBlock({ address }) {
  return (
    <div
      style={{
        padding: '10px 14px',
        backgroundColor: COLOR_PALETTE.slate50,
        borderRadius: '6px',
        border: `1px solid ${COLOR_PALETTE.slate200}`,
        fontSize: '13px',
        lineHeight: '1.6',
        color: COLOR_PALETTE.slate700,
        marginBottom: '8px',
      }}
    >
      <div style={{ fontWeight: 600, marginBottom: '4px', color: COLOR_PALETTE.slate800 }}>
        {LOCALE_STRINGS.address}
      </div>
      <div>{address.street}</div>
      <div>
        {address.city}, {address.state} {address.zip}
      </div>
      <div>{address.country}</div>
      <div style={{ fontSize: '11px', color: COLOR_PALETTE.slate400, marginTop: '4px' }}>
        {address.lat.toFixed(4)}, {address.lng.toFixed(4)}
      </div>
    </div>
  );
}

function MetadataPanel({ metadata }) {
  return (
    <div
      style={{
        padding: '10px 14px',
        backgroundColor: COLOR_PALETTE.indigo50,
        borderRadius: '6px',
        border: `1px solid ${COLOR_PALETTE.indigo200}`,
        fontSize: '13px',
        lineHeight: '1.6',
        marginBottom: '8px',
      }}
    >
      <div
        style={{
          fontWeight: 600,
          marginBottom: '6px',
          color: COLOR_PALETTE.indigo800,
          display: 'flex',
          alignItems: 'center',
        }}
      >
        <CategoryIcon category={metadata.category} size={16} color={COLOR_PALETTE.indigo600} />
        {metadata.category}
      </div>
      <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', marginBottom: '6px' }}>
        <span
          style={{
            color: priorityColor(metadata.priority),
            fontWeight: 600,
            fontSize: '12px',
            padding: '2px 8px',
            borderRadius: '4px',
            backgroundColor: `${priorityColor(metadata.priority)}15`,
          }}
        >
          P{metadata.priority}
        </span>
        {metadata.featured && (
          <span
            style={{
              color: COLOR_PALETTE.amber600,
              fontWeight: 600,
              fontSize: '12px',
              padding: '2px 8px',
              borderRadius: '4px',
              backgroundColor: COLOR_PALETTE.amber50,
            }}
          >
            {LOCALE_STRINGS.featured}
          </span>
        )}
        <span style={{ color: COLOR_PALETTE.slate500, fontSize: '12px' }}>
          {metadata.dimensions.width} x {metadata.dimensions.height}
        </span>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
        {metadata.keywords.map((kw) => (
          <code
            key={kw}
            style={{
              padding: '1px 6px',
              borderRadius: '3px',
              backgroundColor: COLOR_PALETTE.indigo100,
              color: COLOR_PALETTE.indigo700,
              fontSize: '11px',
              fontFamily: 'monospace',
            }}
          >
            {kw}
          </code>
        ))}
      </div>
    </div>
  );
}

function AuthorCard({ author, date, updatedAt }) {
  return (
    <div
      style={{
        display: 'flex',
        gap: '12px',
        alignItems: 'flex-start',
        padding: '10px 14px',
        backgroundColor: COLOR_PALETTE.slate50,
        borderRadius: '6px',
        marginBottom: '10px',
      }}
    >
      <div
        style={{
          width: '48px',
          height: '48px',
          borderRadius: '50%',
          backgroundColor: COLOR_PALETTE.blue200,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '18px',
          fontWeight: 700,
          color: COLOR_PALETTE.blue700,
          flexShrink: 0,
          border: `2px solid ${COLOR_PALETTE.blue300}`,
        }}
      >
        {author.name.charAt(0).toUpperCase()}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 600, fontSize: '14px', color: COLOR_PALETTE.slate800 }}>{author.name}</div>
        <div style={{ fontSize: '12px', color: COLOR_PALETTE.slate500, marginTop: '2px' }}>
          {author.email}
        </div>
        <div style={{ fontSize: '12px', color: COLOR_PALETTE.slate400, marginTop: '4px', lineHeight: '1.5' }}>
          {author.bio}
        </div>
        <div
          style={{
            fontSize: '11px',
            color: COLOR_PALETTE.slate400,
            marginTop: '6px',
            display: 'flex',
            gap: '12px',
          }}
        >
          <span>
            {LOCALE_STRINGS.createdOn} {formatDate(date)}
          </span>
          {updatedAt && (
            <span>
              {LOCALE_STRINGS.updatedOn} {formatDate(updatedAt)}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

function Reply({ reply }) {
  return (
    <div
      style={{
        padding: '8px 12px',
        marginLeft: '24px',
        borderLeft: `2px solid ${COLOR_PALETTE.slate200}`,
        backgroundColor: COLOR_PALETTE.slate50,
        borderRadius: '0 4px 4px 0',
        marginBottom: '4px',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '4px',
        }}
      >
        <span style={{ fontWeight: 600, fontSize: '12px', color: COLOR_PALETTE.slate700 }}>
          {reply.author}
        </span>
        <span
          style={{
            fontSize: '11px',
            color: reply.score >= 0 ? COLOR_PALETTE.green600 : COLOR_PALETTE.red500,
            fontWeight: 500,
          }}
        >
          {reply.score >= 0 ? '+' : ''}
          {reply.score}
        </span>
      </div>
      <p style={{ margin: 0, fontSize: '12px', lineHeight: '1.5', color: COLOR_PALETTE.slate600 }}>
        {reply.text}
      </p>
    </div>
  );
}

function Comment({ comment }) {
  return (
    <div
      style={{
        padding: '12px',
        border: `1px solid ${COLOR_PALETTE.slate200}`,
        borderRadius: '6px',
        marginBottom: '8px',
        backgroundColor: '#fff',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '6px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              width: '28px',
              height: '28px',
              borderRadius: '50%',
              backgroundColor: COLOR_PALETTE.green200,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '12px',
              fontWeight: 700,
              color: COLOR_PALETTE.green700,
            }}
          >
            {comment.author.charAt(0).toUpperCase()}
          </div>
          <span style={{ fontWeight: 600, fontSize: '13px', color: COLOR_PALETTE.slate700 }}>
            {comment.author}
          </span>
          <span style={{ fontSize: '11px', color: COLOR_PALETTE.slate400 }}>
            {formatDate(comment.createdAt)}
          </span>
        </div>
        <span
          style={{
            fontSize: '12px',
            color: comment.score >= 0 ? COLOR_PALETTE.green600 : COLOR_PALETTE.red500,
            fontWeight: 600,
            padding: '2px 8px',
            borderRadius: '10px',
            backgroundColor: comment.score >= 0 ? COLOR_PALETTE.green50 : COLOR_PALETTE.red50,
          }}
        >
          {comment.score >= 0 ? '+' : ''}
          {comment.score}
        </span>
      </div>
      <p style={{ margin: '0 0 8px 0', fontSize: '13px', lineHeight: '1.6', color: COLOR_PALETTE.slate600 }}>
        {comment.text}
      </p>
      {comment.replies && comment.replies.length > 0 && (
        <div style={{ marginTop: '8px' }}>
          {comment.replies.map((r) => (
            <Reply key={r.id} reply={r} />
          ))}
        </div>
      )}
    </div>
  );
}

function CommentList({ comments }) {
  return (
    <div style={{ marginTop: '12px' }}>
      <div
        style={{
          fontWeight: 600,
          fontSize: '14px',
          color: COLOR_PALETTE.slate800,
          marginBottom: '8px',
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
        }}
      >
        {LOCALE_STRINGS.comments}
        <span style={{ fontSize: '12px', color: COLOR_PALETTE.slate400, fontWeight: 400 }}>
          ({comments.length})
        </span>
      </div>
      {comments.map((c) => (
        <Comment key={c.id} comment={c} />
      ))}
    </div>
  );
}

function ItemCard({ item }) {
  return (
    <article
      data-idx={item.id}
      style={{
        padding: '20px 24px',
        margin: '16px 0',
        border: `1px solid ${item.color}`,
        borderLeft: `4px solid ${item.color}`,
        backgroundColor: item.bgColor,
        borderRadius: '8px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      <div
        style={{
          position: 'absolute',
          top: 0,
          right: 0,
          width: '120px',
          height: '120px',
          background: `linear-gradient(135deg, transparent 50%, ${item.color}10 50%)`,
          pointerEvents: 'none',
        }}
      />

      <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
        <ThumbnailImage svg={item.thumbnail} alt={`Thumbnail for item ${item.id}`} width={400} height={300} />

        <div style={{ flex: 1, minWidth: '300px' }}>
          <h3
            style={{
              color: COLOR_PALETTE.slate800,
              fontSize: '16px',
              fontWeight: 700,
              margin: '0 0 6px 0',
              lineHeight: '1.4',
            }}
          >
            #{item.id} — {item.title}
          </h3>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <span style={{ fontSize: '20px', fontWeight: 700, color: item.color }}>
              {formatNumber(item.score)}
            </span>
            <span style={{ fontSize: '12px', color: COLOR_PALETTE.slate400 }}>{LOCALE_STRINGS.score}</span>
          </div>

          <TagCloud tags={item.tags} />

          <AuthorCard author={item.author} date={item.date} updatedAt={item.updatedAt} />
        </div>
      </div>

      <div style={{ margin: '12px 0' }}>
        <p
          style={{ lineHeight: '1.7', color: COLOR_PALETTE.slate600, margin: '0 0 10px 0', fontSize: '14px' }}
        >
          {item.body}
        </p>
        <p
          style={{
            lineHeight: '1.7',
            color: COLOR_PALETTE.slate500,
            margin: '0 0 10px 0',
            fontSize: '13px',
            whiteSpace: 'pre-wrap',
          }}
        >
          {item.description}
        </p>
      </div>

      <StatsBar stats={item.stats} />

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '12px',
          margin: '12px 0',
        }}
      >
        <AddressBlock address={item.address} />
        <MetadataPanel metadata={item.metadata} />
      </div>

      <CommentList comments={item.comments} />
    </article>
  );
}

function SiteHeader({ siteConfig, totalCount, generatedAt }) {
  const { theme } = siteConfig;
  return (
    <header
      style={{
        padding: '24px 32px',
        backgroundColor: theme.primary,
        color: '#fff',
        borderRadius: '8px',
        marginBottom: '24px',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
      }}
    >
      <h1
        style={{
          fontSize: '28px',
          fontWeight: 800,
          margin: '0 0 8px 0',
          fontFamily: theme.fontFamily,
          letterSpacing: '-0.02em',
        }}
      >
        {siteConfig.name} v{siteConfig.version}
      </h1>
      <div style={{ display: 'flex', gap: '24px', fontSize: '14px', opacity: 0.85 }}>
        <span>{totalCount} items rendered</span>
        <span>Locale: {siteConfig.locale}</span>
        <span>Generated: {formatDate(generatedAt)}</span>
      </div>
      <div style={{ marginTop: '12px', display: 'flex', gap: '8px' }}>
        {Object.entries(theme)
          .filter(([k]) => k !== 'fontFamily')
          .map(([k, v]) => (
            <div key={k} style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '11px' }}>
              <div
                style={{
                  width: '14px',
                  height: '14px',
                  borderRadius: '3px',
                  backgroundColor: v,
                  border: '1px solid rgba(255,255,255,0.3)',
                }}
              />
              <span>{k}</span>
            </div>
          ))}
      </div>
    </header>
  );
}

function BundleDataFooter({ itemCount }) {
  const iconPath = getIconPath(`icon_${String(itemCount % TOTAL_ICONS).padStart(5, '0')}`);
  const label = translate('en', 'msg_0001');
  const themeVal = getThemeValue('theme_000', 'card', 'color');
  const assetLen = getAssetChunk(0).length;
  return (
    <footer
      style={{
        marginTop: '32px',
        padding: '16px 24px',
        backgroundColor: COLOR_PALETTE.slate100,
        borderRadius: '6px',
        fontSize: '11px',
        color: COLOR_PALETTE.slate400,
        lineHeight: '1.6',
      }}
    >
      <div>Data version: {DATA_VERSION}</div>
      <div>Icons loaded: {TOTAL_ICONS} | Sample path length: {iconPath.length}</div>
      <div>i18n sample: {label.substring(0, 60)}...</div>
      <div>Theme sample: {themeVal.substring(0, 30)} | Asset chunk size: {formatNumber(assetLen)}</div>
      <svg width="24" height="24" viewBox="0 0 100 100" style={{ display: 'inline-block', verticalAlign: 'middle' }}>
        <path d={iconPath} fill={COLOR_PALETTE.slate300} />
      </svg>
    </footer>
  );
}

function LeakRepro({ items, siteConfig, totalCount, generatedAt }) {
  return (
    <section
      className="leak-repro"
      style={{
        maxWidth: '1200px',
        margin: '0 auto',
        padding: '20px',
        fontFamily: siteConfig?.theme?.fontFamily || 'system-ui, sans-serif',
      }}
    >
      {siteConfig && <SiteHeader siteConfig={siteConfig} totalCount={totalCount} generatedAt={generatedAt} />}
      {items.map((item) => (
        <ItemCard key={item.id} item={item} />
      ))}
      <BundleDataFooter itemCount={items.length} />
    </section>
  );
}

export default LeakRepro;
