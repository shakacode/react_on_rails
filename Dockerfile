# Using Ubuntu Xenial Xerus 16.04 LTS (this is a minimal image with curl and vcs tool pre-installed):
FROM buildpack-deps:xenial

# Install dependencies.
RUN \
  apt-get update \
  && apt-get install tzdata build-essential \
     chrpath libssl-dev libxft-dev libfreetype6 \
     libfreetype6-dev libfontconfig1 libfontconfig1-dev -y

# Install Phantomjs 2.1.1:
ENV PHANTOM_JS=phantomjs-2.1.1-linux-x86_64
RUN \
 wget https://github.com/Medium/phantomjs/releases/download/v2.1.1/$PHANTOM_JS.tar.bz2 \
 && tar xvjf $PHANTOM_JS.tar.bz2 \
 && mv $PHANTOM_JS /usr/local/share \
 && ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin

# Add new user "renderer":
RUN adduser renderer

# Switch to created user and run further commands form its home directory.
# $HOME does not work under ENV directive (https://github.com/moby/moby/issues/2637), so we use custom ENV variable:
USER renderer
ENV USER_HOME=/home/renderer
WORKDIR $USER_HOME

# Install Ruby 2.4.3 from source, set GEM_HOME and expose executable paths:
ENV RUBY_MAJOR_MINOR=2.4
ENV RUBY_VERSION=$RUBY_MAJOR_MINOR.3
RUN \
  wget http://ftp.ruby-lang.org/pub/ruby/$RUBY_MAJOR_MINOR/ruby-$RUBY_VERSION.tar.gz \
  && tar -xvzf ruby-$RUBY_VERSION.tar.gz \
  && rm ruby-$RUBY_VERSION.tar.gz \
  && cd ruby-$RUBY_VERSION/ \
  && ./configure --prefix=$USER_HOME \
  && make \
  && make install
ENV RUBY_HOME=$USER_HOME/ruby-$RUBY_VERSION
ENV GEM_HOME=$RUBY_HOME/gems
ENV PATH=$PATH:$RUBY_HOME:$RUBY_HOME/bin:$RUBY_HOME/gems/bin:

RUN gem install bundler

ENV NODE_VERSION=8.9.4
RUN \
  wget https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz \
  && tar -xvzf node-v$NODE_VERSION-linux-x64.tar.gz \
  && mv node-v$NODE_VERSION-linux-x64 nodejs \
  && rm node-v$NODE_VERSION-linux-x64.tar.gz
ENV PATH=$PATH:$USER_HOME/nodejs/bin:

ENV YARN_VERSION=1.6.0
RUN \
  wget https://github.com/yarnpkg/yarn/releases/download/v$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz \
  && mkdir yarn \
  && tar -xvzf yarn-v$YARN_VERSION.tar.gz -C yarn \
  && rm yarn-v$YARN_VERSION.tar.gz
ENV PATH=$PATH:$USER_HOME/yarn/yarn-v$YARN_VERSION/bin:

# Create a directory for the application and run further commands form there.
RUN mkdir -p project
WORKDIR $USER_HOME/project
