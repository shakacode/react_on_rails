const patterns = [
  /\/(?:Users|home)\/[^\s"']+/g,
  /\/root(?:\/[^\s"']+)?/g,
  /\/(?:private\/)?tmp(?:\/[^\s"']+)?/g,
  /[A-Za-z]:[\\/](?:Users|Documents and Settings)[\\/][^\s"']+/gi,
];

export function redactLocalPaths(value, exactRoots = []) {
  if (value === null || value === undefined) return value;
  let safe = String(value);
  for (const root of exactRoots.filter(Boolean)) safe = safe.replaceAll(root, '<LOCAL_PATH>');
  for (const pattern of patterns) safe = safe.replaceAll(pattern, '<LOCAL_PATH>');
  return safe;
}

export function assertNoLocalPaths(value, exactRoots = []) {
  const pending = [value];
  while (pending.length > 0) {
    const candidate = pending.pop();
    if (typeof candidate === 'string' && redactLocalPaths(candidate, exactRoots) !== candidate) {
      throw new Error('artifact contains an unredacted local path');
    }
    if (Array.isArray(candidate)) pending.push(...candidate);
    else if (candidate !== null && typeof candidate === 'object') pending.push(...Object.values(candidate));
  }
}
