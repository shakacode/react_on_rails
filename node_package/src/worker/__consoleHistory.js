/**
 * Adds console.history polyfill. Note: calling initiConsoleHistory has global side effect
 * for whole process.
 * @module worker/consoleHistory
 */

/**
 *
 */
exports.initiConsoleHistory = function initiConsoleHistory() {
  // Add history to console:
  // eslint-disable-next-line global-require
  require('console.history');


  // Overrirde _collect method of console.history.
  // See https://github.com/lesander/console.history/blob/master/console-history.js for details.
  // eslint-disable-next-line no-underscore-dangle
  console._collect = (type, args) => {
    // Act normal, and just pass all original arguments to the origial console function:
    // eslint-disable-next-line prefer-spread
    console[`_${type}`].apply(console, args);

    // Build console history entry in react_on_rails format:
    const argArray = Array.prototype.slice.call(args);
    if (argArray.length > 0) {
      argArray[0] = `[SERVER] ${argArray[0]}`;
    }

    console.history.push({ level: 'log', arguments: argArray });
  };
};

/**
 *
 */
exports.clearConsoleHistory = function clearConsoleHistory() {
  console.history = [];
};
