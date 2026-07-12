const quotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)\3/gi;
const unterminatedQuotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)$/gim;
const unquotedNamedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*)([^"'\s\n][^\n]*)/gi;
const sensitiveName =
  /^(?:authorization|cookie)$|(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i;
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
  redactStructuredSensitiveValues(value)
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
