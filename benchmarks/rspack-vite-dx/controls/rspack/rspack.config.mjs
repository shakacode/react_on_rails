import { rspack } from '@rspack/core';

export default {
  mode: 'development',
  entry: './src/index.jsx',
  devtool: 'eval-source-map',
  plugins: [new rspack.HtmlRspackPlugin({ template: './index.html' })],
  devServer: {
    host: '127.0.0.1',
    hot: true,
    client: { overlay: true },
  },
};
