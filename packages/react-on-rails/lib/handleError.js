import { createElement } from 'react';
import { renderToString } from "./ReactDOMServer.cjs";
import generateRenderingErrorMessage from "./generateRenderingErrorMessage.js";
const handleError = (options) => {
    const msg = generateRenderingErrorMessage(options);
    const reactElement = createElement('pre', null, msg);
    return renderToString(reactElement);
};
export default handleError;
//# sourceMappingURL=handleError.js.map