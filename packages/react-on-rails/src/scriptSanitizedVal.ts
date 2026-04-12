const scriptSanitizedVal = (val: string): string => {
  // Replace closing
  const re = /<\/\W*script/gi;
  return val.replace(re, '(/script');
};

export default scriptSanitizedVal;
