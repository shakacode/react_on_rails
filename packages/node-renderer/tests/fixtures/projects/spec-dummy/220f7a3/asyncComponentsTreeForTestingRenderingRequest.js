        (function() {
          var railsContext = {"railsEnv":"development","inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","rorVersion":"14.0.5","rorPro":true,"rorProVersion":"4.0.0.rc.5","href":"http://localhost:3000/stream_async_components","location":"/stream_async_components","scheme":"http","host":"localhost","port":3000,"pathname":"/stream_async_components","search":null,"httpAcceptLanguage":"en-US,en-GB;q=0.9,en;q=0.8,ar;q=0.7","somethingUseful":"REALLY USEFUL","serverSide":true};
        
              ReactOnRails.clearHydratedStores();

          var props = {"helloWorldData":{"name":"Mr. Server Side Rendering","\u003cscript\u003ewindow.alert('xss1');\u003c/script\u003e":"\u003cscript\u003ewindow.alert(\"xss2\");\u003c/script\u003e"}};
          return ReactOnRails.streamServerRenderedReactComponent({
            name: 'AsyncComponentsTreeForTesting',
            domNodeId: 'AsyncComponentsTreeForTesting-react-component-0',
            props: props,
            trace: true,
            railsContext: railsContext,
            throwJsErrors: false,
            renderingReturnsPromises: true
          });
        })()
