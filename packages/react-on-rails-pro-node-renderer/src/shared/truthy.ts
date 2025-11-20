export = function truthy(value: unknown) {
  return value === true || value === 'YES' || value === 'TRUE' || value === 'yes' || value === 'true';
};
