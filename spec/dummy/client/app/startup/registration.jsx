import ReactOnRails from 'react-on-rails';

export default function registration(components) {
  ReactOnRails.register(components);

  // Alternate API.
  // Note generatorFunction is specified as a property on the function.
  // ReactOnRails.register('HelloWorld', components.HelloWorld);
  // ReactOnRails.register('HelloWorldWithLogAndThrow', components.HelloWorldWithLogAndThrow);
  // ReactOnRails.register('HelloWorldES5', components.HelloWorldES5);
  // ReactOnRails.register('ReduxApp', components.ReduxApp, { generatorFunction: true});
  // ReactOnRails.register('HelloWorldApp', components.HelloWorldApp, { generatorFunction: true});
  // ReactOnRails.register('RouterApp', components.RouterApp, { generatorFunction: true});
  // Not used for client side
  // ReactOnRails.register('HelloString', HelloString);
}
