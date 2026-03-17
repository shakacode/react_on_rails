import { Readable } from 'stream';
import handleErrorAsString from 'react-on-rails/handleError';
const handleError = (options) => {
    const htmlString = handleErrorAsString(options);
    return Readable.from([htmlString]);
};
export default handleError;
//# sourceMappingURL=handleError.js.map