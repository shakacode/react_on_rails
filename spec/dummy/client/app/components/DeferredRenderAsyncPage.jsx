import React from 'react';

class DeferredRenderAsyncPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = { mounted: 'false' };
  }

  componentDidMount() {
    // eslint-disable-next-line react/no-did-mount-set-state
    this.setState({ mounted: 'true' });
  }

  render() {
    return (
      <div>
        <p>Noice! It works.</p>
        <p>Mounted: {this.state.mounted}</p>
        <p>
          Now, try reloading this page and looking at the developer console. There shouldn&apos;t be any
          client/server mismatch error from React.
        </p>
      </div>
    );
  }
}

export default DeferredRenderAsyncPage;
