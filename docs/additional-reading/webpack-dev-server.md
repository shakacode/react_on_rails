## Developing with the Webpack Dev Server
One of the benefits of using webpack is access to [webpack's dev server](https://webpack.github.io/docs/webpack-dev-server.html) and its [hot module replacement](https://webpack.github.io/docs/hot-module-replacement-with-webpack.html) functionality.

The webpack dev server with HMR will apply changes from the code (or styles!) to the browser as soon as you save whatever file you're working on. You won't need to reload the page, and your data will still be there. Start foreman as normal (it boots up the Rails server *and* the webpack HMR dev server at the same time).

  ```bash
  foreman start -f Procfile.dev
  ```

Open your browser to [localhost:3000](http://localhost:3000). Whenever you make changes to your JavaScript code in the `client` folder, they will automatically show up in the browser. Hot module replacement is already enabled by default.

Note that **React-related error messages are possibly more helpful when encountered in the dev server** than the Rails server as they do not include noise added by the React on Rails gem.

### Adding Additional Routes for the Dev Server
As you add more routes to your front-end application, you will need to make the corresponding API for the dev server in `client/server.js`. See our example `server.js` from our [tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client%2Fserver-express.js).
