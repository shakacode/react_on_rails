import React from 'react';
import type { RailsContext as RailsContextData } from 'react-on-rails/types';

import RailsContext from '../components/RailsContext';

// Example of CSS modules...
import css from '../components/HelloWorld.module.scss';

type HelloWorldData = Record<string, unknown> & {
  name: string;
};

type HelloWorldProps = Record<string, unknown> & {
  helloWorldData: HelloWorldData;
  railsContext?: RailsContextData;
};

type HelloWorldState = HelloWorldData;

// Super simple example of the simplest possible React component
class HelloWorld extends React.Component<HelloWorldProps, HelloWorldState> {
  private nameDomRef: HTMLInputElement | null = null;

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props: HelloWorldProps) {
    super(props);
    this.state = props.helloWorldData;
  }

  handleChange = () => {
    const name = (this.nameDomRef as HTMLInputElement).value;
    this.setState({ name });
  };

  setNameDomRef = (nameDomNode: HTMLInputElement | null) => {
    this.nameDomRef = nameDomNode;
  };

  render() {
    console.log(
      'HelloWorld demonstrating a call to console.log in spec/dummy/client/app/startup/HelloWorld.tsx',
    );

    const { name } = this.state;
    const { railsContext } = this.props;

    return (
      <div>
        <h3 className={css.brightColor}>Hello, {name}!</h3>
        <p>
          Say hello to:
          <input type="text" ref={this.setNameDomRef} defaultValue={name} onChange={this.handleChange} />
        </p>
        {railsContext && <RailsContext {...{ railsContext }} />}
      </div>
    );
  }
}

export type { HelloWorldData, HelloWorldProps };
export default HelloWorld;
