const quotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)\3/gi;
const unterminatedQuotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)$/gim;
const unquotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)([^"'\s\n][^\n]*)/gi;
const sensitiveName =
  /^(?:authorization|cookie)$|(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)|(?:^|[_-])key(?:$|[_-])/i;
const privateKeyBlock = /(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/gis;
const privateKeyRemainder = /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*/gi;
const bearerToken = /bearer\s+[a-z0-9._~+/=-]{12,}/gi;
const nonSecretValues = new Set(['auto', 'false', 'file', 'keyring', 'none', 'null', 'true', 'unknown']);
const looksLikeCredentialValue = (value) => {
  const candidate = String(value).trim();
  if (!candidate || candidate === '[REDACTED]') {
    return false;
  }
  return !nonSecretValues.has(candidate.toLowerCase());
};
const shouldRedact = (name, value) => sensitiveName.test(name) && looksLikeCredentialValue(value);

const decodeUrlName = (value) => {
  try {
    return decodeURIComponent(String(value).replaceAll('+', ' '));
  } catch {
    return String(value);
  }
};

const redactUrlParameters = (value) =>
  String(value)
    .split('&')
    .map((parameter) => {
      const equals = parameter.indexOf('=');
      if (equals < 0 || !sensitiveName.test(decodeUrlName(parameter.slice(0, equals)))) return parameter;
      return `${parameter.slice(0, equals + 1)}[REDACTED]`;
    })
    .join('&');

const redactUrlCredentials = (url) => {
  const schemeEnd = url.indexOf('://') + 3;
  const authorityEndMatch = url.slice(schemeEnd).search(/[/?#]/);
  const authorityEnd = authorityEndMatch < 0 ? url.length : schemeEnd + authorityEndMatch;
  let safe = url;
  const at = safe.lastIndexOf('@', authorityEnd);
  if (at >= schemeEnd) {
    const colon = safe.indexOf(':', schemeEnd);
    if (colon >= schemeEnd && colon < at) {
      safe = `${safe.slice(0, colon + 1)}[REDACTED]${safe.slice(at)}`;
    }
  }
  const currentAuthorityMatch = safe.slice(schemeEnd).search(/[/?#]/);
  const currentAuthorityEnd = currentAuthorityMatch < 0 ? safe.length : schemeEnd + currentAuthorityMatch;
  const query = safe.indexOf('?', currentAuthorityEnd);
  const fragment = safe.indexOf('#', currentAuthorityEnd);
  if (query >= 0) {
    const queryEnd = fragment >= 0 ? fragment : safe.length;
    safe = `${safe.slice(0, query + 1)}${redactUrlParameters(safe.slice(query + 1, queryEnd))}${safe.slice(queryEnd)}`;
  }
  const safeFragment = safe.indexOf('#', currentAuthorityEnd);
  if (safeFragment >= 0) {
    safe = `${safe.slice(0, safeFragment + 1)}${redactUrlParameters(safe.slice(safeFragment + 1))}`;
  }
  return safe;
};

const redactCredentialsInWebUrls = (value) =>
  String(value).replace(/https?:\/\/[^\s"']+/gi, (url) => redactUrlCredentials(url));

const structuredValueEnd = (value, start) => {
  const stack = [value[start] === '{' ? '}' : ']'];
  let quote = null;
  let escaped = false;
  for (let index = start + 1; index < value.length; index += 1) {
    const character = value[index];
    if (quote !== null) {
      if (escaped) escaped = false;
      else if (character === '\\') escaped = true;
      else if (character === quote) quote = null;
    } else if (character === '"' || character === "'") {
      quote = character;
    } else if (character === '{' || character === '[') {
      stack.push(character === '{' ? '}' : ']');
    } else if (character === '}' || character === ']') {
      if (character !== stack.at(-1)) return value.length;
      stack.pop();
      if (stack.length === 0) return index + 1;
    }
  }
  return value.length;
};

const redactStructuredSensitiveValues = (value) => {
  const input = String(value);
  const pattern = /([a-z0-9_-]+)(["']?\s*[:=]\s*)([[{])/gi;
  let output = '';
  let cursor = 0;
  while (true) {
    const match = pattern.exec(input);
    if (match === null) break;
    if (sensitiveName.test(match[1])) {
      const start = match.index + match[0].length - 1;
      const end = structuredValueEnd(input, start);
      output += `${input.slice(cursor, start)}[REDACTED]`;
      cursor = end;
      pattern.lastIndex = end;
    }
  }
  return output + input.slice(cursor);
};

export const redactSensitiveValues = (value) =>
  redactStructuredSensitiveValues(redactCredentialsInWebUrls(value))
    .replace(quotedNamedValue, (match, name, separator, quote, quotedValue) =>
      shouldRedact(name, quotedValue) ? `${name}${separator}${quote}[REDACTED]${quote}` : match,
    )
    .replace(unterminatedQuotedNamedValue, (match, name, separator, quote, quotedValue) =>
      shouldRedact(name, quotedValue) ? `${name}${separator}${quote}[REDACTED]` : match,
    )
    .replace(unquotedNamedValue, (match, name, separator, unquotedValue) =>
      shouldRedact(name, unquotedValue) ? `${name}${separator}[REDACTED]` : match,
    )
    .replace(privateKeyBlock, '[REDACTED]')
    .replace(privateKeyRemainder, '[REDACTED]')
    .replace(bearerToken, 'Bearer [REDACTED]');

export const containsSensitiveValues = (value) => redactSensitiveValues(value) !== String(value);
