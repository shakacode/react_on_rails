FROM ruby:3.3.7

RUN apt-get update

# install node and yarn
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash
RUN apt-get install -y nodejs
RUN npm install -g yarn

WORKDIR /app

# install ruby gems
COPY Gemfile Gemfile.development_dependencies Gemfile.lock react_on_rails_pro.gemspec .
COPY lib ./lib

ENV BUNDLE_FROZEN=true
RUN bundle config set without 'development test' && \
    bundle config set with 'staging production' && \
    bundle install --jobs=3 --retry=3

# install node packages
COPY package.json yarn.lock .
RUN yarn install --frozen-lockfile

# pick necessary app files
COPY spec/ ./spec
COPY app/ ./app
COPY lib/ ./lib
COPY packages/ ./packages
COPY rakelib/ ./rakelib

WORKDIR /app/spec/dummy

ENV BUNDLE_FROZEN=true
RUN bundle config set without 'development test' && \
    bundle config set with 'staging production' && \
    bundle install --jobs=3 --retry=3

RUN yarn global add yalc
RUN yarn install --frozen-lockfile

ENV NODE_ENV=production
ENV RAILS_ENV=production

RUN rails assets:precompile

EXPOSE 3000 3800

CMD ["rails", "s", "-p", "3000"]
