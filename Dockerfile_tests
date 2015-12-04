FROM dylangrafmyre/docker-ci

WORKDIR /app/

COPY ["/lib/react_on_rails/version.rb", "/app/lib/react_on_rails/"]
COPY ["Gemfile", "Gemfile.lock", "react_on_rails.gemspec", "rakelib/", "/app/"]
COPY ["/spec/dummy/Gemfile", "/spec/dummy/Gemfile.lock", "/app/spec/dummy/"]
RUN  bundle install --gemfile=spec/dummy/Gemfile

ENV DISPLAY :99
ENTRYPOINT service xvfd start \
           && rake
