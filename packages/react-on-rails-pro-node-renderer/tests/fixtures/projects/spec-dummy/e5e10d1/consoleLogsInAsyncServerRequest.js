(function () {
  var railsContext = {
    railsEnv: 'development',
    inMailer: false,
    i18nLocale: 'en',
    i18nDefaultLocale: 'en',
    rorVersion: '14.0.5',
    rorPro: true,
    rorProVersion: '4.0.0.rc.5',
    href: 'http://localhost:3000/console_logs_in_async_server',
    location: '/console_logs_in_async_server',
    scheme: 'http',
    host: 'localhost',
    port: 3000,
    pathname: '/console_logs_in_async_server',
    search: null,
    httpAcceptLanguage: 'en-US,en-GB;q=0.9,en;q=0.8,ar;q=0.7',
    somethingUseful: 'REALLY USEFUL',
    serverSide: true,
  };

  ReactOnRails.clearHydratedStores();

  var props = { requestId: '6ce0caf9-2691-472a-b59b-5de390bcffdf' };
  return ReactOnRails.serverRenderReactComponent({
    name: 'ConsoleLogsInAsyncServer',
    domNodeId: 'ConsoleLogsInAsyncServer-react-component',
    props: props,
    trace: true,
    railsContext: railsContext,
    throwJsErrors: false,
    renderingReturnsPromises: true,
  });
})();
