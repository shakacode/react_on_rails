import React, { PropTypes } from 'react';
import RailsContext from './RailsContext';

// Super simple example of the simplest possible React component
export default class HelloWorldRedux extends React.Component {

  static propTypes = {
    actions: PropTypes.object.isRequired,
    data: PropTypes.object.isRequired,
    railsContext: PropTypes.object.isRequired,
  };

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props) {
    super(props);
    this.setNameDomRef = this.setNameDomRef.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
  }

  handleChange() {
    const name = this.nameDomRef.value;
    this.props.actions.updateName(name);
  }

  render() {
    const { data, railsContext } = this.props;
    const { name } = data;

    // If this creates an alert, we have a problem!
    // see file node_package/src/scriptSanitizedVal.js for the fix to this prior issue.
    console.log('This is a script:"</div>"</script> <script>alert(\'WTF1\')</script>');
    console.log('Script2:"</div>"</script xx> <script>alert(\'WTF2\')</script xx>');
    console.log('Script3:"</div>"</  SCRIPT xx> <script>alert(\'WTF3\')</script xx>');
    console.log('Script4"</div>"</script <script>alert(\'WTF4\')</script>');
    console.log('Script5:"</div>"</ script> <script>alert(\'WTF5\')</script>');

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
        <RailsContext {...{ railsContext }} />
      </div>
    );
  }
}
