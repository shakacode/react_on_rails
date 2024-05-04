import PropTypes from 'prop-types';
import React from 'react';
import RailsContext from '../components/RailsContext';

import css from '../components/HelloWorld.module.scss';

class HelloTurboStream extends React.Component {
  static propTypes = {
    helloTurboStreamData: PropTypes.shape({
      name: PropTypes.string,
    }).isRequired,
    railsContext: PropTypes.object,
  };

  constructor(props) {
    super(props);
    this.state = props.helloTurboStreamData;
    this.setNameDomRef = this.setNameDomRef.bind(this);
    this.handleChange = this.handleChange.bind(this);
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
        <h3 className={css.brightColor}>Hello, {name}!</h3>
        {railsContext && <RailsContext {...{ railsContext }} />}
      </div>
    );
  }
}

export default HelloTurboStream;
