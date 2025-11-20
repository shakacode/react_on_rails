(function () {
  var railsContext = {
    railsEnv: 'development',
    inMailer: false,
    i18nLocale: 'en',
    i18nDefaultLocale: 'en',
    rorVersion: '11.3.0',
    rorPro: true,
    href: 'http://localhost:3000/server_side_redux_app',
    location: '/server_side_redux_app',
    scheme: 'http',
    host: 'localhost',
    port: 3000,
    pathname: '/server_side_redux_app',
    search: null,
    httpAcceptLanguage: 'en-US,en;q=0.9',
    somethingUseful: 'REALLY USEFUL',
    serverSide: true,
  };

  ReactOnRails.clearHydratedStores();

  var props = {
    helloWorldData: {
      name: 'Mr. Server Side Rendering',
      "\u003cscript\u003ewindow.alert('xss1');\u003c/script\u003e":
        '\u003cscript\u003ewindow.alert("xss2");\u003c/script\u003e',
    },
  };
  return ReactOnRails.serverRenderReactComponent({
    name: 'ReduxApp',
    domNodeId: 'ReduxApp-react-component-0',
    props: props,
    trace: true,
    railsContext: railsContext,
  });
})();
