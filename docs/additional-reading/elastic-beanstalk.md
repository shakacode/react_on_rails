# Deploying React on Rails to Elastic Beanstalk

In order to deploy a React on Rails app to elastic beanstalk, you must install yarn on each instance.
If yarn is not installed, asset compilation will fail on the elastic beanstalk instance.

You can install yarn by adding a `yarn.config` file to your `.ebextensions` folder which contains these commands.

```
commands:

  01_node_get:
    cwd: /tmp
    command: 'sudo curl --silent --location https://rpm.nodesource.com/setup_6.x | sudo bash -'

  02_node_install:
    cwd: /tmp
    command: 'sudo yum -y install nodejs'

  03_yarn_get:
    cwd: /tmp
    # don't run the command if yarn is already installed (file /usr/bin/yarn exists)
    test: '[ ! -f /usr/bin/yarn ] && echo "yarn not installed"'
    command: 'sudo wget https://dl.yarnpkg.com/rpm/yarn.repo -O /etc/yum.repos.d/yarn.repo'

  04_yarn_install:
    cwd: /tmp
    test: '[ ! -f /usr/bin/yarn ] && echo "yarn not installed"'
    command: 'sudo yum -y install yarn'

```

