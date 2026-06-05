import React from 'react';
import ReactOnRails from 'react-on-rails/client';
import RailsContext from '../components/RailsContext';
import type { RailsContextForDisplay } from '../types/railsContext';

type HelloWorldRehydratableData = Record<string, unknown> & {
  name: string;
};

type HelloWorldRehydratableProps = Record<string, unknown> & {
  helloWorldData: HelloWorldRehydratableData;
  railsContext?: RailsContextForDisplay;
};

class HelloWorldRehydratable extends React.Component<
  HelloWorldRehydratableProps,
  HelloWorldRehydratableData
> {
  private nameDomRef: HTMLInputElement | null = null;

  constructor(props: HelloWorldRehydratableProps) {
    super(props);
    this.state = props.helloWorldData;
  }

  componentDidMount() {
    document.addEventListener('hydrate', this.forceClientHydration);
  }

  componentWillUnmount() {
    document.removeEventListener('hydrate', this.forceClientHydration);
  }

  handleChange = () => {
    if (!this.nameDomRef) return;

    this.setState({ name: this.nameDomRef.value });
  };

  setNameDomRef = (nameDomNode: HTMLInputElement | null) => {
    this.nameDomRef = nameDomNode;
  };

  forceClientHydration = () => {
    const registeredComponentName = 'HelloWorldRehydratable';
    const { railsContext } = this.props;
    const matchingComponents = document.querySelectorAll(
      `[id^="${CSS.escape(registeredComponentName)}-react-component-"]`,
    );

    for (let i = 0; i < matchingComponents.length; i += 1) {
      const component = matchingComponents.item(i);
      const componentSpecificationTag = document.querySelector<HTMLScriptElement>(
        `script[data-dom-id="${CSS.escape(component.id)}"]`,
      );

      if (!componentSpecificationTag?.textContent) {
        throw new Error(`Missing component specification for ${component.id}`);
      }

      const componentProps = JSON.parse(componentSpecificationTag.textContent) as Record<string, unknown>;
      const mergedProps: Record<string, unknown> = { ...componentProps, railsContext };
      ReactOnRails.render(registeredComponentName, mergedProps, component.id, true);
    }
  };

  render() {
    const { name } = this.state;
    const { railsContext } = this.props;

    return (
      <div>
        <h3>Hello, {name}!</h3>
        <p>
          Say hello to:
          <input type="text" ref={this.setNameDomRef} defaultValue={name} onChange={this.handleChange} />
        </p>
        {railsContext && <RailsContext railsContext={railsContext} />}
      </div>
    );
  }
}

export default HelloWorldRehydratable;
