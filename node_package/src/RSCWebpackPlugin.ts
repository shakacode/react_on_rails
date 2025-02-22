import { Compiler } from "webpack";
import RSCWebpackPluginLib from "react-server-dom-webpack/plugin";

type ClientReferenceSearchPath = {
  directory: string,
  recursive?: boolean,
  include: RegExp,
  exclude?: RegExp,
};

type ClientReferencePath = string | ClientReferenceSearchPath;

export type Options = {
  isServer: boolean,
  clientReferences?: ClientReferencePath | ReadonlyArray<ClientReferencePath>,
  chunkName?: string,
  clientManifestFilename?: string,
  serverConsumerManifestFilename?: string,
};

export class RSCWebpackPlugin {
  private plugin?: RSCWebpackPluginLib;

  constructor(options: Options) {
    if (!options.isServer) {
      this.plugin = new RSCWebpackPluginLib(options);
    }
  }

  apply(compiler: Compiler) {
    this.plugin?.apply(compiler);
  }
}
