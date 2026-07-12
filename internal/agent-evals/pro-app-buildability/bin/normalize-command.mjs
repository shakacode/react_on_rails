const shellQuote = (value) => {
  const argument = String(value);
  if (/^[A-Za-z0-9_./:@%+=,-]+$/.test(argument)) return argument;
  return `'${argument.replaceAll("'", `'"'"'`)}'`;
};

export const normalizeCommand = (value) => {
  if (typeof value === 'string') return value;
  if (!Array.isArray(value)) return '';
  if (value.length === 3 && /^\/bin\/(?:zsh|bash|sh)$/.test(String(value[0])) && value[1] === '-lc') {
    return String(value[2]);
  }
  return value.map(shellQuote).join(' ');
};
