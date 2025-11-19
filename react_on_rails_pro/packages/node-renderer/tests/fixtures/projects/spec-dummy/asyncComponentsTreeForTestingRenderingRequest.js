(function(componentName = 'AsyncComponentsTreeForTesting', props = undefined) {
  var railsContext = {"componentRegistryTimeout":5000,"railsEnv":"development","inMailer":false,"i18nLocale":"en","i18nDefaultLocale":"en","rorVersion":"15.0.0.alpha.2","rorPro":true,"rscPayloadGenerationUrl":"rsc_payload/","rorProVersion":"4.0.0.rc.13","href":"http://localhost:3000/stream_async_components_for_testing","location":"/stream_async_components_for_testing","scheme":"http","host":"localhost","port":3000,"pathname":"/stream_async_components_for_testing","search":null,"httpAcceptLanguage":"en-US,en-GB;q=0.9,en;q=0.8,ar;q=0.7","somethingUseful":"REALLY USEFUL","serverSide":true};
  railsContext.reactClientManifestFileName = 'react-client-manifest.json';
  railsContext.reactServerClientManifestFileName = 'react-server-client-manifest.json';

  railsContext.serverSideRSCPayloadParameters = {
    renderingRequest,
    rscBundleHash: '88888-test',
  }

  const runOnOtherBundle = globalThis.runOnOtherBundle;
  if (typeof generateRSCPayload !== 'function') {
    globalThis.generateRSCPayload = function generateRSCPayload(componentName, props, railsContext) {
      const { renderingRequest, rscBundleHash } = railsContext.serverSideRSCPayloadParameters;
      const propsString = JSON.stringify(props);
      const newRenderingRequest = renderingRequest.replace(/\(\s*\)\s*$/, `('${componentName}', ${propsString})`);
      return runOnOtherBundle(rscBundleHash, newRenderingRequest);
    }
  }

  ReactOnRails.clearHydratedStores();
  var usedProps = typeof props === 'undefined' ? {"helloWorldData":{"name":"Mr. Server Side Rendering","\u003cscript\u003ewindow.alert('xss1');\u003c/script\u003e":"\u003cscript\u003ewindow.alert(\"xss2\");\u003c/script\u003e"}} : props;
  
  if (ReactOnRails.isRSCBundle) {
    var { props: propsWithAsyncProps, asyncPropManager } = ReactOnRails.addAsyncPropsCapabilityToComponentProps(usedProps);
    usedProps = propsWithAsyncProps;
    sharedExecutionContext.set("asyncPropsManager", asyncPropManager);
  }

  return ReactOnRails[ReactOnRails.isRSCBundle ? 'serverRenderRSCReactComponent' : 'streamServerRenderedReactComponent']({
    name: componentName,
    domNodeId: 'AsyncComponentsTreeForTesting-react-component-0',
    props: usedProps,
    trace: true,
    railsContext: railsContext,
    throwJsErrors: false,
    renderingReturnsPromises: true,
  });
})()
