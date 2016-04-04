import React, {PropTypes} from 'react';
import RailsContext from './RailsContext';

// Super simple example of the simplest possible React component
export default class HelloWorldRedux extends React.Component {

  static propTypes = {
    actions: PropTypes.object.isRequired,
    data: PropTypes.object.isRequired,
    railsContext: PropTypes.object.isRequired,
  };

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
    this.setNameDomRef = this.setNameDomRef.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  handleChange() {
    const name = this.nameDomRef.value;
    this.props.actions.updateName(name);
  }

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
  }

  render() {
    const {data, railsContext} = this.props;
    const {name} = data;

    // If this creates an alert, we have a problem!
    // see file node_package/src/scriptSanitizedVal.js for the fix to this prior issue.
    console.log('This is a script:"</div>"</script> <script>alert(\'WTF\')</script>');

    return (
      <div>
        <h3>
          Redux Hello, {name}!
        </h3>
        <p>
          With Redux, say hello to:
          <input
            type="text"
            ref={this.setNameDomRef}
            value={name}
            onChange={this.handleChange}
          />
        </p>
        <RailsContext {...{railsContext}} />
      </div>
    );
  }
}
