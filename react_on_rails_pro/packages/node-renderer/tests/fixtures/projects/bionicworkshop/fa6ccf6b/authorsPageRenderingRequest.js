(function() {
  var railsContext = {"inMailer":false,"i18nLocale":"ru","i18nDefaultLocale":"ru","href":"http://0.0.0.0:3000/authors","location":"/authors","scheme":"http","host":"0.0.0.0","port":3000,"pathname":"/authors","search":null,"httpAcceptLanguage":"ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4","appVersion":"v1.5.4-1-g6d0afe8\n","authenticityToken":"vVqS4gfg4uVzU8o2mxyXNHZSb7eo8cXo8LHSHOKFr70/z/dwqcbb3kvq3U219YU5iuWYTx9WGcCTCDadT6kG8A==","serverSide":true};
      ReactOnRails.clearHydratedStores();
var reduxProps, store, storeGenerator;
reduxProps = {"authors_init_data":{"authors":{"list":[{"id":"1-denis-udovenko","name":"Денис Удовенко","description":"Автор этого сайта. Большинство публикаций направлено на компенсацию недостатка информации о современном протезировании и изложение личного опыта.","accepts_feedbacks":true,"posts_count":4,"avatar_thumb_url":"/uploads/avatar/image/471/thumb_8db4d733-b57d-4278-b600-fd9f68843e22.jpg","avatar_preview_url":"/uploads/avatar/image/471/preview_8db4d733-b57d-4278-b600-fd9f68843e22.jpg"}],"page":1,"per_page":10,"total":1}}};
storeGenerator = ReactOnRails.getStoreGenerator('Store');
store = storeGenerator(reduxProps, railsContext);
ReactOnRails.setStore('Store', store);

  var props = {};
  return ReactOnRails.serverRenderReactComponent({
    name: 'App',
    domNodeId: 'react-root',
    props: props,
    trace: true,
    railsContext: railsContext
  });
})()
