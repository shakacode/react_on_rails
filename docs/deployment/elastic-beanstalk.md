# Deploying React on Rails to Elastic Beanstalk

In order to deploy a React on Rails app to elastic beanstalk, you must install yarn on each instance.
If yarn is not installed, asset compilation will fail on the elastic beanstalk instance.

You can install `yarn` by adding a `0x_install_yarn.config` file to your `.ebextensions` folder which contains these commands.

```
files:
  "/opt/elasticbeanstalk/hooks/appdeploy/pre/09_yarn.sh" :
    mode: "000755"
    owner: root
    group: root
    content: |
      #!/usr/bin/env bash
      set -xe

      EB_SCRIPT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k script_dir)
      EB_APP_STAGING_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k app_staging_dir)
      EB_APP_USER=$(/opt/elasticbeanstalk/bin/get-config container -k app_user)
      EB_SUPPORT_DIR=$(/opt/elasticbeanstalk/bin/get-config container -k support_dir)

      . $EB_SUPPORT_DIR/envvars
      . $EB_SCRIPT_DIR/use-app-ruby.sh

      # Install nodejs
      echo "install nodejs"
      curl --silent --location https://rpm.nodesource.com/setup_6.x | sudo bash -
      yum -y install nodejs
      echo "install yarn"
      # install yarn
      wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo;
      yum -y install yarn;

      # yarn install
      cd $EB_APP_STAGING_DIR
      yarn

      # mkdir /home/webapp
      mkdir -p /home/webapp
      chown webapp:webapp /home/webapp
      chmod 700 /home/webapp
```

This script installs `yarn` and all `node.js` dependencies before the rails do `assets:precompile`. Also, it creates `/home/webapp` directory allowing the precompile task to create temp files. 

Your app can be deployed to elastic beanstalk successfully. However, the react app javascript files are under `public/packs`. If you are using nginx, you need to let it know the location of `https://yourhost/packs`. 

In your `proxy.conf` setting, please add the following code.

```
...
server{
  ...
  location /packs {
    root /var/app/current/public;
  }
  ...
}
...
```

You can find an example code here: https://github.com/imgarylai/react_on_rails_with_aws_ebs.
