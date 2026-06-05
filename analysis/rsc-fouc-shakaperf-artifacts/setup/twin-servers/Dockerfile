ARG RUBY_VERSION=3.3.7
ARG NODE_VERSION=22.12.0

FROM node:${NODE_VERSION}-bookworm AS node
FROM ruby:${RUBY_VERSION}-bookworm

ARG NON_ROOT_USER=rails
ARG UID=1000
ARG GID=1000
ARG PNPM_VERSION=10.33.4

# The secret-key value is a fixed dummy for this hermetic SQLite test image:
# no real data, credentials, or external services are present in the artifact.
ENV APP_PATH=/home/${NON_ROOT_USER}/app \
    BUNDLE_PATH=/home/${NON_ROOT_USER}/bundle \
    GEM_HOME=/home/${NON_ROOT_USER}/bundle \
    PNPM_HOME=/home/${NON_ROOT_USER}/.local/share/pnpm \
    PATH=/home/${NON_ROOT_USER}/.local/share/pnpm:/home/${NON_ROOT_USER}/bundle/bin:/usr/local/bin:$PATH \
    RAILS_ENV=test \
    NODE_ENV=test \
    TWIN_SERVERS=true \
    SECRET_KEY_BASE=dummy-secret-key-base-for-shakaperf-rsc-fouc \
    REACT_RENDERER_URL=http://localhost:3800

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -sf ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libsqlite3-dev \
      pkg-config \
      python3 \
      sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Some base images already reserve GID 1000; clear any matching group first so
# the non-root test user can own bind-mounted artifacts consistently.
RUN getent group ${GID} | cut -d: -f1 | xargs -r groupdel || true \
    && groupadd --gid ${GID} ${NON_ROOT_USER} \
    && useradd ${NON_ROOT_USER} --uid ${UID} --gid ${GID} --create-home --shell /bin/bash \
    && mkdir -p ${APP_PATH} ${BUNDLE_PATH} ${PNPM_HOME} \
    && chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}

RUN npm install -g corepack@0.31.0 \
    && corepack enable \
    && corepack prepare pnpm@${PNPM_VERSION} --activate

USER ${NON_ROOT_USER}
WORKDIR ${APP_PATH}

# Copy the filtered repo context before installs because this monorepo's Bundler
# and pnpm workspace resolution need package/gemspec files across the checkout.
COPY --chown=${NON_ROOT_USER}:${NON_ROOT_USER} . .

RUN bundle install --jobs=4 --retry=3
RUN pnpm install --frozen-lockfile
RUN pnpm run build
RUN cd react_on_rails_pro/spec/dummy \
    && bundle install --jobs=4 --retry=3 \
    && bundle exec rake react_on_rails:generate_packs \
    && pnpm run build:test \
    && RAILS_ENV=test bundle exec rails db:prepare

EXPOSE 3000 3800

# Twin-servers starts processes through Overmind; no CMD/ENTRYPOINT here.
