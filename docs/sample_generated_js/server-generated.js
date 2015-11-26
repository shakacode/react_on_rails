(function() {
  var htmlResult = '';
  var consoleReplayScript = '';
  var hasErrors = false;

  try {
    htmlResult =
      (function() {
        return this.HelloString.world();
      })();
  } catch(e) {
    htmlResult = ReactOnRails.handleError({e: e, componentName: null,
      jsCode: 'this.HelloString.world()', serverSide: true});
    hasErrors = true;
  }

  consoleReplayScript = ReactOnRails.buildConsoleReplay();

  return JSON.stringify({
      html: htmlResult,
      consoleReplayScript: consoleReplayScript,
      hasErrors: hasErrors
  });

})()
