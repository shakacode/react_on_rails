import type { RailsContext } from 'react-on-rails/types';

const HelloWorldWithLogAndThrow = (_props: Record<string, unknown>, _railsContext: RailsContext): never => {
  console.log('console.log in HelloWorld');
  console.warn('console.warn in HelloWorld');
  console.error('console.error in HelloWorld');
  throw new Error('throw in HelloWorldWithLogAndThrow');
};

export default HelloWorldWithLogAndThrow;
