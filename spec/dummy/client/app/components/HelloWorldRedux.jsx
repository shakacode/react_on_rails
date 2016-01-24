import React, { PropTypes } from 'react';
import ReactDOM from 'react-dom';

// Super simple example of the simplest possible React component
export default class HelloWorldRedux extends React.Component {

  static propTypes = {
    actions: PropTypes.object.isRequired,
    data: PropTypes.object.isRequired,
  };

  // Not necessary if we only call super, but we'll need to initialize state, etc.
  constructor(props, context) {
    super(props, context);
  }

  _handleChange() {
    const name = ReactDOM.findDOMNode(this.refs.name).value;
    this.props.actions.updateName(name);
  }

  render() {
    const { data } = this.props;
    const { name } = data;

    return (
      <div>
        <h3>
          Redux Hello, {name}!
        </h3>
        <p>
          With Redux, say hello to:
          <input type="text" ref="name" defaultValue={name} onChange={::this._handleChange} />
        </p>
      </div>
    );
  }
}
