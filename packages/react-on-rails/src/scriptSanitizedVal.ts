export default (val: string): string => {
  // Replace closing
  const re = /<\/\s*script/gi;
  return val.replace(re, '(/script');
};
