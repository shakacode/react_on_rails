const consoleErrorReporter = ({error}) => {
  if (typeof console === 'undefined') {
    throw error;
  }
  console.error(error); // eslint-disable-line
  return null;
};

export default consoleErrorReporter;
