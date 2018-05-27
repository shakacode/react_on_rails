import PropTypes from 'prop-types';
import React from 'react';
import ReactOnRails from 'react-on-rails';
import RailsContext from './RailsContext';

class HelloWorldRehydratable extends React.Component {

  static propTypes = {
    helloWorldData: PropTypes.shape({
      name: PropTypes.string,
    }).isRequired,
    railsContext: PropTypes.object,
  };

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props) {
    super(props);
    this.state = props.helloWorldData;
    this.setNameDomRef = this.setNameDomRef.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.forceClientHydration = this.forceClientHydration.bind(this)
  }

  componentDidMount() {
    document.addEventListener('hydrate', this.forceClientHydration);
  }

  componentWillUnmount() {
    document.removeEventListener('hydrate', this.forceClientHydration);
  }

  forceClientHydration() {
    const registeredComponentName = 'HelloWorldRehydratable';
    const { railsContext } = this.props;

    // Target all instances of the component in the DOM
    const match = document.querySelectorAll(`[id^=${registeredComponentName}-react-component-]`);
    // Not all browsers support forEach on NodeList so we go with a classic for-loop
    for (let i = 0; i < match.length; ++i) {
      const component = match[i];

      // Get component specification <script> tag
      let domNode = component;
      while (domNode && !domNode.classList.contains('js-react-on-rails-component')) {
        // Before ReactOnRails v11.0.7, component specifications where inserted before the actual component
        // See https://github.com/shakacode/react_on_rails/commit/912118445f55c6f59664bf2b9f9ed97779ee71c9
        // You may have to replace "nextElementSibling" by "previousElementSibling" if you use an older version
        domNode = domNode.nextElementSibling;
      }

      if (domNode) {
        // Read props from the component specification tag and merge railsContext
        const mergedProps = {...JSON.parse(domNode.textContent), railsContext};
        // Hydrate
        ReactOnRails.render(registeredComponentName, mergedProps, component.id);
      }
    }
  }

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
  }

  handleChange() {
    const name = this.nameDomRef.value;
    this.setState({ name });
  }

  render() {
    const { name } = this.state;
    const { railsContext } = this.props;

    return (
      <div>
        <h3>
          Hello, {name}!
        </h3>
        <p>
          Say hello to:
          <input
            type="text"
            ref={this.setNameDomRef}
            defaultValue={name}
            onChange={this.handleChange}
          />
        </p>
        { railsContext && <RailsContext {...{ railsContext }} /> }
      </div>
    );
  }
}

export default HelloWorldRehydratable;
