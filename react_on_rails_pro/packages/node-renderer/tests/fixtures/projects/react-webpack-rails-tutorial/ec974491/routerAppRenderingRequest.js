(function() {
  var railsContext = {"inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","href":"http://0.0.0.0:5000/","location":"/","scheme":"http","host":"0.0.0.0","port":5000,"pathname":"/","search":null,"httpAcceptLanguage":"ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4","serverSide":true};
      ReactOnRails.clearHydratedStores();
var reduxProps, store, storeGenerator;
reduxProps = {"comments":[{"id":2,"author":"Vasya","text":"Another test","created_at":"2017-05-22T01:45:32.043Z","updated_at":"2017-05-22T01:45:32.043Z"},{"id":1,"author":"Denis","text":"Test","created_at":"2017-05-22T01:45:15.667Z","updated_at":"2017-05-22T01:45:15.667Z"}]};
storeGenerator = ReactOnRails.getStoreGenerator('routerCommentsStore');
store = storeGenerator(reduxProps, railsContext);
ReactOnRails.setStore('routerCommentsStore', store);

  var props = {};
  return ReactOnRails.serverRenderReactComponent({
    name: 'RouterApp',
    domNodeId: 'RouterApp-react-component-0',
    props: props,
    trace: true,
    railsContext: railsContext
  });
})()
