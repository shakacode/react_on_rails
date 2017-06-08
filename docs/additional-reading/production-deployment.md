#Deploying to Production

Since this application uses a mix of Rails and NPM conventions you should carefully consider your production deployment process. Typically with a Rails application you will "vendorize" your GEM dependencies (commit them along with your code so that the production deployment doesn't risk downloading slightly different versions of your libraries).  

With NPM you can shrinkwrap your dependencies (tag a specific version of the dependency for download) but you do not typically commit the `node_modules` directory to your repo. This means that when your application is built, you are generally downloading all of the dependencies from NPM at deployment time. A better alternative is to build your code for production and save/deploy the resulting artifact. This will remove the requirement of building your application from your production servers and guarantee that you are deploying exactly the same code to every environment/server.

## Elastic Beanstalk
When deploying to AWS' Elastic Beanstalk, the deployment process includes running a production NPM build:

```
  cd client && npm run build:production
  
  > react-webpack-rails-tutorial@0.0.1 build:production /var/app/ondeck/client
  > NODE_ENV=production webpack --config webpack.config.js
```

However, since the modules required to actually build the project are (properly) configured in the `client/package.json`'s `devDependencies` section, the production server does not have them available which results in an error similar to:

```
  ERROR in Missing binding /var/app/ondeck/client/node_modules/node-sass/vendor/linux-x64-46/binding.node
  Node Sass could not find a binding for your current environment: Linux 64-bit with Node.js 4.x
```

To resolve this, you need to be able to create a production build with dev dependencies and deploy the resulting artifact. This will trigger the webpack build of the productionized assets and move them into the correct location for the Rails Asset Pipeline.

The `pkgr` gem can do this job well, but this tool requires that the build be run on the same os you are deploying to (not a development laptop for example). This is a paid service, but should be able to be run on a EC2 instance with minimal configuration. Perhaps Travis would be another runtime environment that this could work on in conjunction with other CI tasks.