import { renderToPipeableStream } from 'react-on-rails-rsc/server.node';
import generateRenderingErrorMessage from 'react-on-rails/generateRenderingErrorMessage';
const handleError = (options) => {
    const msg = generateRenderingErrorMessage(options);
    return renderToPipeableStream(new Error(msg), {
        filePathToModuleMetadata: {},
        moduleLoading: { prefix: '', crossOrigin: null },
    });
};
export default handleError;
//# sourceMappingURL=handleErrorRSC.js.map