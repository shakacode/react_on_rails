(function () {
  var railsContext = {
    inMailer: false,
    i18nLocale: 'ru',
    i18nDefaultLocale: 'ru',
    href: 'http://0.0.0.0:3000/',
    location: '/',
    scheme: 'http',
    host: '0.0.0.0',
    port: 3000,
    pathname: '/',
    search: null,
    httpAcceptLanguage: 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4',
    appVersion: 'v1.5.4-1-g6d0afe8\n',
    authenticityToken:
      'aNhS0Ruo+1YLg6nJD+Orv5IzvT1xuMt7p7yr0GtCz6PqTTdDtY7CbTM6vrIhCrmyboRKxcYfF1PEBU9Rxm5m7g==',
    serverSide: true,
  };
  ReactOnRails.clearHydratedStores();
  var reduxProps, store, storeGenerator;
  reduxProps = {
    posts_init_data: {
      posts: {
        list: [
          {
            id: '9-esche',
            title: 'Еще',
            description: 'Еще статья блеать',
            published_at_utc: '2016-12-29 04:11',
            author_id: '1-denis-udovenko',
            tags_ids: ['2-ottobock', '3-gilzy', '5-dlinnyi-tag'],
            images_sizes: {
              6: {
                width: 640,
                height: 493,
                src: '/uploads/rich/rich_file/rich_file_file_name/6/bebionic.jpg',
              },
              7: {
                width: 796,
                height: 448,
                src: '/uploads/rich/rich_file/rich_file_file_name/7/axon_16_9_video_preview.jpg',
              },
              14: { width: 590, height: 300, src: '/uploads/rich/rich_file/rich_file_file_name/14/soap.jpg' },
              23: {
                width: 1920,
                height: 1200,
                src: '/uploads/rich/rich_file/rich_file_file_name/23/images.jpg',
              },
            },
            videos_count: 1,
            comments_count: 18,
          },
          {
            id: '8-esche-statya',
            title: 'Еще статья',
            description: 'Еще одна статья',
            published_at_utc: '2016-12-24 07:42',
            author_id: '1-denis-udovenko',
            tags_ids: ['1-bebionic', '2-ottobock', '5-dlinnyi-tag'],
            images_sizes: {
              8: { width: 485, height: 600, src: '/uploads/rich/rich_file/rich_file_file_name/8/11.jpg' },
              17: { width: 264, height: 232, src: '/uploads/rich/rich_file/rich_file_file_name/17/5.jpg' },
            },
            videos_count: 0,
            comments_count: 0,
          },
          {
            id: '7-agrarnye-problemy-antarktiki',
            title: 'Аграрные проблемы Антарктики',
            description: 'Разбираемся с аграрными проблемами Антарктики',
            published_at_utc: '2016-12-21 21:49',
            author_id: '1-denis-udovenko',
            tags_ids: ['1-bebionic', '2-ottobock', '3-gilzy', '5-dlinnyi-tag'],
            images_sizes: {
              21: {
                width: 796,
                height: 448,
                src: '/uploads/rich/rich_file/rich_file_file_name/21/axon_16_9_video_preview.jpg',
              },
            },
            videos_count: 0,
            comments_count: 0,
          },
          {
            id: '6-megastatya-pro-kiborgov',
            title: 'Мегастатья про киборгов',
            description: 'Короче опять про киборгов',
            published_at_utc: '2016-12-17 21:49',
            author_id: '1-denis-udovenko',
            tags_ids: ['2-ottobock', '3-gilzy', '5-dlinnyi-tag'],
            images_sizes: {},
            videos_count: 0,
            comments_count: 0,
          },
        ],
        page: 1,
        per_page: 10,
        total: 4,
      },
      authors: {
        list: [
          {
            id: '1-denis-udovenko',
            name: 'Денис Удовенко',
            description:
              'Автор этого сайта. Большинство публикаций направлено на компенсацию недостатка информации о современном протезировании и изложение личного опыта.',
            accepts_feedbacks: true,
            posts_count: 4,
            avatar_thumb_url: '/uploads/avatar/image/471/thumb_8db4d733-b57d-4278-b600-fd9f68843e22.jpg',
            avatar_preview_url: '/uploads/avatar/image/471/preview_8db4d733-b57d-4278-b600-fd9f68843e22.jpg',
          },
        ],
      },
      tags: {
        list: [
          { id: '1-bebionic', posts_count: 2, name: 'BeBionic' },
          { id: '2-ottobock', posts_count: 4, name: 'OttoBock' },
          { id: '3-gilzy', posts_count: 3, name: 'Гильзы' },
          { id: '5-dlinnyi-tag', posts_count: 4, name: 'Длинный таг' },
        ],
        page: 1,
        per_page: 0,
        total: 4,
      },
    },
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
