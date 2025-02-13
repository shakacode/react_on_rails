import ReactOnRails from './ReactOnRails';
import { ReactComponent } from './types';

const registerServerComponent = (components: { [id: string]: ReactComponent }) => {
  ReactOnRails.register(components);
};

export default registerServerComponent;
