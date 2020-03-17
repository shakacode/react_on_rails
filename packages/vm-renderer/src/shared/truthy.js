module.exports = function truthy(value) {
  return value === true || value === 'YES' || value === 'TRUE' || value === 'yes' || value === 'true';
};
