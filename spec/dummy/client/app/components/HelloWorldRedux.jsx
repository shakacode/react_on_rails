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

  handleChange() {
    const name =  this.nameDomRef.name;
    this.setState({ name });
  }

  setNameDomRef(nameDomNode) {
    this.nameDomRef = nameDomNode;
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
          <input type="text" ref={this.setNameDomRef} defaultValue={name} onChange={::this.handleChange} />
        </p>
      </div>
    );
  }
}
