(function() {
  var railsContext = {"inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","href":"http://app.lvh.me:3000/","location":"/","scheme":"http","host":"app.lvh.me","port":3000,"pathname":"/","search":null,"httpAcceptLanguage":"ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4","railsEnv":"development","honeybadgerEnv":"development","launchdarklyAllFlags":{"blv_redux":false,"temp-calendar":true},"launchdarklySettings":{"key":"3917","anonymous":false,"email":"justin@friendsandguests.com","firstName":"Justin","lastName":"Gordon"},"cloudinaryUrl":"https://res.cloudinary.com/dsm07vjyu/image/upload/","desktop":true,"tablet":false,"mobile":false,"userId":3917,"userEmail":"justin@friendsandguests.com","serverSide":true};
      ReactOnRails.clearHydratedStores();
var reduxProps, store, storeGenerator;
reduxProps = {"navbar":{"publicPaths":{"listingsIndexPath":"/s","aboutPath":"/about","faqPath":"/faq","pricingPath":"/pricing","communityUrl":"https://community.friendsandguests.com/login","hostsPath":"/hosts"},"user":{"id":3917,"avatarUrl":"https://res.cloudinary.com/dsm07vjyu/image/gravatar/d_default_avatar.png/60ffe5c75d594b26bfe72bace107f421.png","firstName":"Justin","messagesPath":"/inbox","profilePath":"/users/justingordon951","accountPath":"/account/edit","signOutPath":"/users/sign_out","adminPath":"/admin","listingsCount":0,"invitationsCount":0,"conversationsCount":0,"guestListMembershipRequestsCount":0},"signedInPaths":{"listingInvitationsPath":"/listing_invitations","joinedListingInvitationsPath":"/listing_memberships","favoritesPath":"/favorites","managePropertiesPath":"/manage/listings","newListingPath":"/manage/listings/new"}}};
storeGenerator = ReactOnRails.getStoreGenerator('appStore');
store = storeGenerator(reduxProps, railsContext);
ReactOnRails.setStore('appStore', store);

  var props = {};
  return ReactOnRails.serverRenderReactComponent({
    name: 'LayoutNavbar',
    domNodeId: 'LayoutNavbar-react-component-9262e955-8eb5-4114-9ce5-bc9a53962271',
    props: props,
    trace: true,
    railsContext: railsContext
  });
})()
