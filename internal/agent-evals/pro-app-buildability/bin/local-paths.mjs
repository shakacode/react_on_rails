const webUrlPattern = /(https?:\/\/[^\s"']+)/gi;
const localPathPatterns = [
  /\/(?:Users|home)\/[^/\s"']+(?:\/[^\s"']*)?/g,
  /\/root(?:\/[^\s"']*)?/g,
  /\/private\/tmp(?:\/[^\s"']*)?/g,
  /\/tmp\/[^\s"']+/g,
  /\/var\/folders\/[^\s"']+/g,
];
const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const mapOutsideWebUrls = (value, transform) =>
  String(value)
    .split(webUrlPattern)
    .map((part) => (/^https?:\/\//i.test(part) ? part : transform(part)))
    .join('');

export const redactLocalPaths = (value, exactRoots = []) =>
  mapOutsideWebUrls(value, (part) => {
    let safe = part;
    for (const root of exactRoots) {
      safe = safe.replaceAll(new RegExp(`${escapeRegExp(root)}(?=$|[/\\s"',;:)\\]}])`, 'g'), '<LOCAL_PATH>');
    }
    for (const pattern of localPathPatterns) safe = safe.replaceAll(pattern, '<LOCAL_PATH>');
    return safe;
  });

export const containsLocalPaths = (value) => redactLocalPaths(value) !== String(value);
