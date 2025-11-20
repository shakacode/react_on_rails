(function() {
  var railsContext = {"inMailer":false,"i18nLocale":"ru","i18nDefaultLocale":"ru","href":"http://0.0.0.0:3000/posts/8-esche-statya","location":"/posts/8-esche-statya","scheme":"http","host":"0.0.0.0","port":3000,"pathname":"/posts/8-esche-statya","search":null,"httpAcceptLanguage":"ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4","appVersion":"v1.5.4-1-g6d0afe8\n","authenticityToken":"+iSmQdkP8aXFL99dJOeVTh8G6RvofTZD7Y6QpJ0NSlp4scPTdynInv2WyCYKDodD47Ee41/a6muON3QlMCHjFw==","serverSide":true};
      ReactOnRails.clearHydratedStores();
var reduxProps, store, storeGenerator;
reduxProps = {"post_init_data":{"post":{"id":"8-esche-statya","title":"Еще статья","description":"Еще одна статья","content":"\u003cp\u003e\u003cimg alt=\"\" data-rich-file-id=\"17\" src=\"/uploads/rich/rich_file/rich_file_file_name/17/landscape_5.jpg\" /\u003eБла\u003cimg alt=\"\" class=\"default\" data-rich-file-id=\"8\" src=\"/uploads/rich/rich_file/rich_file_file_name/8/portrait_11.jpg\" /\u003e\u003c/p\u003e\r\n","published_at_utc":"2016-12-24 07:42","author_id":"1-denis-udovenko","tags_ids":["1-bebionic","2-ottobock","5-dlinnyi-tag"],"images_sizes":{"8":{"width":485,"height":600,"src":"/uploads/rich/rich_file/rich_file_file_name/8/11.jpg"},"17":{"width":264,"height":232,"src":"/uploads/rich/rich_file/rich_file_file_name/17/5.jpg"}},"videos_count":0,"comments_count":0},"authors":{"list":[{"id":"1-denis-udovenko","name":"Денис Удовенко","description":"Автор этого сайта. Большинство публикаций направлено на компенсацию недостатка информации о современном протезировании и изложение личного опыта.","accepts_feedbacks":true,"posts_count":4,"avatar_thumb_url":"/uploads/avatar/image/471/thumb_8db4d733-b57d-4278-b600-fd9f68843e22.jpg","avatar_preview_url":"/uploads/avatar/image/471/preview_8db4d733-b57d-4278-b600-fd9f68843e22.jpg"}],"page":1,"per_page":0,"total":1},"tags":{"list":[{"id":"1-bebionic","posts_count":2,"name":"BeBionic"},{"id":"2-ottobock","posts_count":4,"name":"OttoBock"},{"id":"5-dlinnyi-tag","posts_count":4,"name":"Длинный таг"}]},"comments":{"list":[],"page":1,"per_page":0,"total":0}}};
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
