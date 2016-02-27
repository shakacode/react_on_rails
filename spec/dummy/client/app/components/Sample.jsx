/*
  Component: Sample
*/

import React from 'react';
import Relay from 'react-relay';

class Sample extends React.Component {
  render() {
    return (
      <div className="sample">
        <h3>Sample component name: { this.props.sample.name }</h3>
      </div>
    );
  }
}

module.exports = Sample;

/*
  Relay Container: Comment
  Defines data need for this component
*/

const SampleContainer = Relay.createContainer(Sample, {
  fragments: {
    sample: () => Relay.QL`
      fragment on Sample {
        name,
      }
    `,
  },
});

module.exports = SampleContainer;
