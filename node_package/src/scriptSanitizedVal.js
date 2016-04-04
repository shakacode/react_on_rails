export default (val) => {
  // Replace closing
  const re = /<\/\W*script\W*>/gi;
  return val.replace(re, '(/script)');
};
