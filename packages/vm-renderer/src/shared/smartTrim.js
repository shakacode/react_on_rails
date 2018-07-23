import { getConfig } from '../shared/configBuilder';


export const TRUNCATION_FILLER = '\n... TRUNCATED ...\n';

// From https://stackoverflow.com/a/831583/1009332
export default function smartTrim(string, maxLength = getConfig().maxDebugSnippetLength) {
  if (!string) return string;
  if (maxLength < 1) return string;
  if (string.length <= maxLength) return string;
  if (maxLength === 1) return string.substring(0, 1) + TRUNCATION_FILLER;

  const midpoint = Math.ceil(string.length / 2);
  const toRemove = string.length - maxLength;
  const lstrip = Math.ceil(toRemove / 2);
  const rstrip = toRemove - lstrip;
  return string.substring(0, midpoint - lstrip) + TRUNCATION_FILLER
    + string.substring(midpoint + rstrip);
}
