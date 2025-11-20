(function () {
  var railsContext = {
    inMailer: false,
    i18nLocale: 'ru',
    i18nDefaultLocale: 'ru',
    href: 'http://0.0.0.0:3000/users/sign-in',
    location: '/users/sign-in',
    scheme: 'http',
    host: '0.0.0.0',
    port: 3000,
    pathname: '/users/sign-in',
    search: null,
    httpAcceptLanguage: 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4',
    appVersion: 'v1.5.4-1-g6d0afe8\n',
    authenticityToken:
      'gnVz8X0d14ED4eVOs43lhP63qRiafnfE7KQpmxspmoEjNmNWXpw+WgT/pLjCQoSLVMayN41NeTPUZUsWZaPRRg==',
    serverSide: true,
  };
  ReactOnRails.clearHydratedStores();
  var reduxProps, store, storeGenerator;
  reduxProps = {
    flashes_init_data: [{ message: 'Вам необходимо войти в систему или зарегистрироваться.', type: 'alert' }],
  };
  storeGenerator = ReactOnRails.getStoreGenerator('Store');
  store = storeGenerator(reduxProps, railsContext);
  ReactOnRails.setStore('Store', store);

  var props = {};
  return ReactOnRails.serverRenderReactComponent({
    name: 'App',
    domNodeId: 'react-root',
    props: props,
    trace: true,
    railsContext: railsContext,
  });
})();
