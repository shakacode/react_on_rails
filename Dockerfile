FROM ruby:2.2.3
MAINTAINER Dylan Grafmyre <dylan@shakacode.com>

RUN mkdir -p /app
WORKDIR /app/
# Setup container for linting with ruby and npm
RUN gem install rubocop ruby-lint scss_lint
RUN curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
RUN apt-get install -y nodejs
RUN npm install -g eslint \
  eslint-config-airbnb \
  eslint-plugin-react \
  babel-eslint \
  jscs
