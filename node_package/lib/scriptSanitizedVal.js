export default (val) => {
  // Replace closing
  const re = /<\/\W*script/gi;
  return val.replace(re, '(/script');
};
