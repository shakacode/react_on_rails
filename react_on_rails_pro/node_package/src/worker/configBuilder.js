/**
 * Reads CLI arguments and build the config.
 * @module worker/configBuilder
 */

let port = process.env.PORT || 3700;

module.exports = function configBuilder() {
  let currentArg;

  process.argv.forEach((val) => {
    if (val[0] === '-') {
      currentArg = val.slice(1);
      return;
    }

    if (currentArg === 'p') {
      port = val;
    }
  });

  return { port };
};
