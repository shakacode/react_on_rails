const namedValue = /([a-z0-9_-]+)(["']?\s*[:=]\s*["']?)([^,"'\n]+)/gi;
const sensitiveName =
  /^(?:authorization|cookie)$|(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i;
const privateKeyBlock = /(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/gis;
const privateKeyHeader = /-----BEGIN [A-Z ]*PRIVATE KEY-----/i;
const bearerToken = /bearer\s+[a-z0-9._-]{12,}/i;
const nonSecretValues = new Set(['auto', 'false', 'file', 'keyring', 'none', 'null', 'true', 'unknown']);
const looksLikeCredentialValue = (value) => {
  const candidate = String(value).trim();
  if (!candidate || candidate === '[REDACTED]' || candidate.startsWith('[') || candidate.startsWith('{')) {
    return false;
  }
  return !nonSecretValues.has(candidate.toLowerCase());
};

export const redactSensitiveValues = (value) =>
  String(value)
    .replace(namedValue, (match, name, separator) =>
      sensitiveName.test(name) ? `${name}${separator}[REDACTED]` : match,
    )
    .replace(privateKeyBlock, '$1[REDACTED]$2');

export const containsSensitiveValues = (value) => {
  const content = String(value);
  if (bearerToken.test(content) || privateKeyHeader.test(content)) return true;
  for (const match of content.matchAll(namedValue)) {
    if (sensitiveName.test(match[1]) && looksLikeCredentialValue(match[3])) return true;
  }
  return false;
};
