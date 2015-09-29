(function() {
  var props = {"helloWorldData":{"name":"Mr. Server Side Rendering"}};
  return ReactOnRails.serverRenderReactComponent({
    componentName: 'HelloWorld',
    domId: 'HelloWorld-react-component-0',
    propsVarName: '__helloWorldData0__',
    props: props,
    trace: true,
    generatorFunction: false
  });
})();
