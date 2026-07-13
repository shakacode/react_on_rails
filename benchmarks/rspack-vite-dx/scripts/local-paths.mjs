const webUrlPattern = /(https?:\/\/[^\s"']+)/gi;
const localDevServerUrlPattern =
  /^https?:\/\/(?:localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]|\[::\])(?::\d+)?\//i;
const spacedPathSegment = String.raw`[^\\/\r\n"',;:)\]}]+`;
// A whitespace-free terminal segment keeps unquoted trailing prose outside the match.
// Final segments containing spaces must be quoted or escaped by the producing tool.
const terminalPathSegment = String.raw`[^\\/\s\r\n"',;:)\]}]+`;
const pathBoundary = String.raw`(?=$|[\r\n"',;:)\]}])`;
const pathTail = String.raw`(?:[\\/]${spacedPathSegment})*[\\/]${terminalPathSegment}`;
const fixedRootSuffix = String.raw`(?:${pathTail}|${pathBoundary})`;
const userPath = String.raw`(?:${spacedPathSegment}${pathTail}|${terminalPathSegment}${pathBoundary})`;
const localPathPatterns = [
  new RegExp(String.raw`\/(?:Users|home)\/${userPath}`, 'g'),
  new RegExp(String.raw`\/root${fixedRootSuffix}`, 'g'),
  new RegExp(String.raw`\/(?:private\/)?tmp${fixedRootSuffix}`, 'g'),
  new RegExp(String.raw`\/(?:private\/)?var\/folders${fixedRootSuffix}`, 'g'),
  new RegExp(String.raw`[A-Za-z]:[\\/](?:Users|Documents and Settings)[\\/]${userPath}`, 'gi'),
];

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const mapOutsideWebUrls = (value, transform) =>
  String(value)
    .split(webUrlPattern)
    .map((part) =>
      /^https?:\/\//i.test(part) && !localDevServerUrlPattern.test(part) ? part : transform(part),
    )
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
    (root) =>
      new RegExp(`${escapeRegExp(root)}${fixedRootSuffix}`, /^[A-Za-z]:[\\/]/.test(root) ? 'gi' : 'g'),
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
