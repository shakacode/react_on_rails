import React from 'react';

import type { HelloWorldNameUpdateAction } from '../actions/HelloWorldActions';
import type { HelloWorldData } from '../store/reduxTypes';
import type { RailsContextForDisplay } from '../types/railsContext';
import RailsContext from './RailsContext';

type HelloWorldReduxActions = {
  updateName(name: string): HelloWorldNameUpdateAction;
};

type HelloWorldReduxProps = {
  actions: HelloWorldReduxActions;
  data: HelloWorldData;
  railsContext: RailsContextForDisplay;
};

export default class HelloWorldRedux extends React.Component<HelloWorldReduxProps> {
  private nameDomRef: HTMLInputElement | null = null;

  handleChange = () => {
    const name = this.nameDomRef?.value;

    if (name !== undefined) {
      this.props.actions.updateName(name);
    }
  };

  setNameDomRef = (nameDomNode: HTMLInputElement | null) => {
    this.nameDomRef = nameDomNode;
  };

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
        <h3>Redux Hello, {name}!</h3>
        <p>
          With Redux, say hello to:
          <input type="text" ref={this.setNameDomRef} value={name} onChange={this.handleChange} />
        </p>
        <RailsContext railsContext={railsContext} />
      </div>
    );
  }
}

export type { HelloWorldReduxActions, HelloWorldReduxProps };
