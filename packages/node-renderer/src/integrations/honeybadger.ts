import { notify } from '@honeybadger-io/js';
import { addNotifier } from '../shared/errorReporter';

export function init() {
  addNotifier((msg) => notify(msg));
}
