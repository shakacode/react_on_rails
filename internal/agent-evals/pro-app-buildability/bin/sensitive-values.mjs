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
  if (!candidate || candidate === '[REDACTED]' || candidate.startsWith('[') || candidate.startsWith('{')) {
    return false;
  }
  return !nonSecretValues.has(candidate.toLowerCase());
};
const shouldRedact = (name, value) => sensitiveName.test(name) && looksLikeCredentialValue(value);

export const redactSensitiveValues = (value) =>
  String(value)
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
