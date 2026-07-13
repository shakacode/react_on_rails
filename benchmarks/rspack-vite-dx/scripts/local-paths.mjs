const webUrlPattern = /(https?:\/\/[^\s"']+)/gi;
const loopbackWebUrlPattern = /^https?:\/\/(?:localhost|127\.0\.0\.1|\[::1\])(?::\d+)?\//i;
const pathTail = String.raw`(?:[\\/][^\s"',;:)\]}]+)*`;
const localPathPatterns = [
  new RegExp(String.raw`\/(?:Users|home)\/[^/\s"',;:)\]}]+${pathTail}`, 'g'),
  new RegExp(String.raw`\/root${pathTail}`, 'g'),
  new RegExp(String.raw`\/(?:private\/)?tmp${pathTail}`, 'g'),
  new RegExp(String.raw`\/(?:private\/)?var\/folders${pathTail}`, 'g'),
  new RegExp(
    String.raw`[A-Za-z]:[\\/](?:Users|Documents and Settings)[\\/][^\\/\s"',;:)\]}]+${pathTail}`,
    'gi',
  ),
];

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const mapOutsideWebUrls = (value, transform) =>
  String(value)
    .split(webUrlPattern)
    .map((part) => (/^https?:\/\//i.test(part) && !loopbackWebUrlPattern.test(part) ? part : transform(part)))
    .join('');

export const redactLocalPaths = (value, exactRoots = []) => {
  if (value === null || value === undefined) return value;

  const rootVariants = exactRoots
    .filter(Boolean)
    .flatMap((root) => [
      String(root),
      String(root).replaceAll('\\', '/'),
      String(root).replaceAll('/', '\\'),
    ]);
  const exactRootPatterns = [...new Set(rootVariants)].map(
    (root) => new RegExp(`${escapeRegExp(root)}${pathTail}`, /^[A-Za-z]:[\\/]/.test(root) ? 'gi' : 'g'),
  );
  return mapOutsideWebUrls(value, (part) => {
    let safe = part;
    for (const pattern of exactRootPatterns) safe = safe.replaceAll(pattern, '<LOCAL_PATH>');
    for (const pattern of localPathPatterns) safe = safe.replaceAll(pattern, '<LOCAL_PATH>');
    return safe;
  });
};

export const assertNoLocalPaths = (value, exactRoots = []) => {
  const pending = [value];
  while (pending.length > 0) {
    const candidate = pending.pop();
    if (typeof candidate === 'string' && redactLocalPaths(candidate, exactRoots) !== candidate) {
      throw new Error('artifact contains an unredacted local path');
    }
    if (Array.isArray(candidate)) {
      pending.push(...candidate);
    } else if (candidate !== null && typeof candidate === 'object') {
      for (const [key, nestedValue] of Object.entries(candidate)) pending.push(key, nestedValue);
    }
  }
};
