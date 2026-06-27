# Docker Deployment

This guide covers deploying a React on Rails application using Docker containers, with specific instructions for Kamal, Kubernetes, and Control Plane.

## Dockerfile for React on Rails

Rails 7.1+ ships with a production-ready `Dockerfile`. React on Rails needs Node.js available during the build stage to compile JavaScript bundles. Here is a representative multi-stage Dockerfile:

```dockerfile
# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.3
ARG NODE_VERSION=20

###############################################################################
# Base stage — shared between build and runtime
###############################################################################
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    NODE_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

###############################################################################
# Build stage — install gems, Node, and compile assets
###############################################################################
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential curl git libpq-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn (or use corepack for pnpm/yarn)
ARG NODE_VERSION
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    corepack enable && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install JS dependencies
COPY package.json yarn.lock ./
RUN yarn install --immutable  # Yarn Berry (v2+); for Yarn Classic (v1), use --frozen-lockfile

# Copy the full application
COPY . .

# Precompile assets (builds client and server bundles)
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# Remove node_modules — not needed at runtime and saves hundreds of MBs
RUN rm -rf node_modules

###############################################################################
# Runtime stage — lean image for production
###############################################################################
FROM base

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

<p align="center">
  <img src="images/docker-multi-stage-build.svg" alt="A three-stage Docker build for React on Rails. The base stage sets the shared Ruby image and production environment. The build stage adds Node.js and build tools, installs gems and JS dependencies, runs assets:precompile to build the client and server bundles, then deletes node_modules. The runtime stage starts fresh from base and copies in only the built artifacts — gems, compiled bundles, and app code — leaving Node.js and node_modules behind, producing a lean production image hundreds of megabytes smaller." width="840" />
</p>

### Key points

- **Node.js is only needed at build time.** The runtime stage does not include Node unless you use the Pro Node Renderer (see [Node Renderer in containers](#node-renderer-in-containers) below).
- **`SECRET_KEY_BASE_DUMMY=1`** lets `assets:precompile` run without a real secret. Rails 7.1+ supports this natively.
- **Server bundles** land in `ssr-generated/` (private, never served to browsers) while client bundles land in `public/webpack/production/`. Both are copied into the runtime image.
- If you use `config.build_production_command`, it runs during `assets:precompile`. See [Configuration](../configuration/README.md#build_production_command).
- **Add a `.dockerignore` file** to prevent host-specific files from being copied into the build. Without it, `COPY . .` can overwrite the freshly installed `node_modules/` with modules built for a different OS/architecture. A minimal `.dockerignore` (expand as appropriate for your project):

  ```text
  node_modules
  .git
  log
  tmp
  spec
  test
  .github
  ```

### Using pnpm instead of Yarn

Replace the Yarn lines with:

```dockerfile
RUN corepack enable && corepack prepare pnpm@10.33.4 --activate  # match packageManager in package.json

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
```

## Environment variables

Set these at runtime (not baked into the image):

| Variable                   | Purpose                                                               |
| -------------------------- | --------------------------------------------------------------------- |
| `SECRET_KEY_BASE`          | Rails secret key                                                      |
| `DATABASE_URL`             | Database connection string                                            |
| `RAILS_SERVE_STATIC_FILES` | Set to `true` when there is no CDN or reverse proxy serving `/public` |
| `RAILS_LOG_TO_STDOUT`      | Set to `true` for container log collection                            |
| `RAILS_ENV`                | Should be `production`                                                |

## Deploying with Kamal

[Kamal](https://kamal-deploy.org/) deploys Docker containers to bare servers over SSH using Traefik as a reverse proxy. It is the default deployment tool for Rails 8.

### Setup

```bash
bundle add kamal
kamal init
```

### config/deploy.yml

```yaml
service: myapp

image: your-registry/myapp

servers:
  web:
    hosts:
      - 192.168.0.1
    options:
      memory: 512m

proxy:
  ssl: true
  host: myapp.example.com

registry:
  server: ghcr.io
  username: your-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_SERVE_STATIC_FILES: true
    RAILS_LOG_TO_STDOUT: true
  secret:
    - SECRET_KEY_BASE
    - DATABASE_URL

builder:
  arch: amd64
```

### Deploy

```bash
kamal setup    # first deploy — provisions Traefik
kamal deploy   # subsequent deploys
```

### Kamal tips for React on Rails

- **Build caching**: Kamal uses Docker layer caching. Structure your Dockerfile so `Gemfile.lock` and `yarn.lock` are copied before the full source to maximize cache hits.
- **Health checks**: Kamal probes `/up` by default (Rails 7.1+). Ensure this route is defined.
- **Asset serving**: Set `RAILS_SERVE_STATIC_FILES=true` or configure an asset host / CDN.
- **Memory**: Webpack/Rspack compilation is memory-intensive. If building on the server, allocate at least 2 GB for the builder. Using remote builds (`builder.remote`) avoids this issue.

## Deploying with Kubernetes

### Container image

Build and push your image to a container registry:

```bash
docker build -t your-registry/myapp:latest .
docker push your-registry/myapp:latest
```

### Deployment manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: rails
          image: your-registry/myapp:latest
          ports:
            - containerPort: 3000
          env:
            - name: RAILS_ENV
              value: production
            - name: RAILS_SERVE_STATIC_FILES
              value: 'true'
            - name: RAILS_LOG_TO_STDOUT
              value: 'true'
            - name: SECRET_KEY_BASE
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: secret-key-base
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: database-url
          readinessProbe:
            httpGet:
              path: /up
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /up
              port: 3000
            initialDelaySeconds: 60
            periodSeconds: 20
          resources:
            requests:
              memory: '256Mi'
              cpu: '250m'
            limits:
              memory: '512Mi'
              cpu: '1000m'
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

### Kubernetes tips for React on Rails

- **Secrets**: Use Kubernetes Secrets with `secretKeyRef` (as shown above) rather than hardcoding values directly in the `env` section. Never commit secret values to your manifest files.
- **Migrations**: Run migrations as a Kubernetes Job or init container before the Deployment rolls out:

  > [!WARNING]
  > With `replicas > 1`, each pod's init container runs concurrently. Prefer a Kubernetes Job for migrations unless every migration is idempotent.

  ```yaml
  initContainers:
    - name: migrate
      image: your-registry/myapp:latest
      command: ['bundle', 'exec', 'rails', 'db:migrate']
      env:
        - name: RAILS_ENV
          value: production
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: secret-key-base
  ```

- **Horizontal Pod Autoscaler**: Scale based on CPU or custom metrics. React on Rails apps doing SSR are CPU-bound, so CPU-based scaling is a good starting point.
- **Ingress**: Use an Ingress controller (nginx-ingress, Traefik, etc.) with TLS termination in front of the Service.

## Deploying with Control Plane

[Control Plane](https://controlplane.com/) provides Heroku-like ease of use with Kubernetes-level infrastructure. ShakaCode maintains the [Control Plane Flow](https://github.com/shakacode/control-plane-flow/) gem (`cpflow`) for Rails deployments.

### Setup

```bash
gem install cpflow
cpflow setup
```

This creates a `.controlplane/` directory with configuration templates.

### .controlplane/controlplane.yml

```yaml
aliases:
  common: &common
    cpln_org: your-org
    location: aws-us-east-2
    one_off_workload: rails
    app_workloads:
      - rails
    additional_workloads:
      - redis
      - postgres

apps:
  myapp:
    <<: *common
```

### .controlplane/templates/rails.yml

Control Plane workloads are similar to Kubernetes Deployments. Key settings for React on Rails:

```yaml
kind: workload
name: rails
spec:
  type: standard
  containers:
    - name: rails
      cpu: '500m'
      memory: 512Mi
      ports:
        - number: 3000
          protocol: http
      env:
        - name: RAILS_ENV
          value: production
        - name: RAILS_SERVE_STATIC_FILES
          value: 'true'
        - name: RAILS_LOG_TO_STDOUT
          value: 'true'
        - name: SECRET_KEY_BASE
          value: 'cpln://secret/myapp-secrets.SECRET_KEY_BASE'
        - name: DATABASE_URL
          value: 'cpln://secret/myapp-secrets.DATABASE_URL'
      readinessProbe:
        httpGet:
          path: /up
          port: 3000
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        httpGet:
          path: /up
          port: 3000
        initialDelaySeconds: 60
        periodSeconds: 20
```

### Deploy

```bash
cpflow build-image -a myapp    # build + push image to registry
cpflow deploy-image -a myapp   # deploy the pushed image to Control Plane
```

### Control Plane tips for React on Rails

- **GVC environment variables**: Set shared environment variables at the GVC level so all workloads inherit them. See the [Control Plane Flow guide to secrets and ENV values](https://github.com/shakacode/control-plane-flow/blob/main/docs/secrets-and-env-values.md).
- **Secrets**: Use Control Plane's built-in secrets management (`cpln://secret/...`) instead of environment variables for sensitive values.
- **One-off tasks**: Run migrations and other one-off commands via `cpflow run -a myapp -- bundle exec rails db:migrate`.
- **Public demo and starter staging apps**: Keep `type: standard` workloads
  with `minScale: 1`, the autoscaling metric disabled, and `capacityAI: true`.
  Avoid CPU Utilization autoscaling pinned to `minScale: 1` / `maxScale: 1`,
  because that prevents Capacity AI from right-sizing the warm workload. When
  the autoscaling metric is disabled, do not rely on `maxScale` for bursts; use
  a compatible autoscaling metric for that separate scaling posture. Use
  `serverless` scale-to-zero only as an explicit first-deploy choice or planned
  delete/recreate migration. See the
  [Control Plane Flow capacity tips](https://github.com/shakacode/control-plane-flow/blob/main/docs/tips.md#enable-capacity-ai-for-demo-and-starter-staging-apps).
- **Multiple locations**: Control Plane supports multi-region deployment. Add locations to your GVC to deploy globally.

## Node Renderer in containers

If you use [React on Rails Pro's Node Renderer](../building-features/node-renderer/basics.md) for high-performance SSR, the runtime image needs Node.js.

### Multi-container setup

Run the Node Renderer as a separate container/sidecar alongside the Rails container. The node-renderer container needs a separate image that includes Node.js — the main runtime image from the [Dockerfile above](#dockerfile-for-react-on-rails) does not include Node.

```yaml
# Kubernetes example — two containers in one Pod
containers:
  - name: rails
    image: your-registry/myapp:latest
    ports:
      - containerPort: 3000
    env:
      - name: REACT_RENDERER_URL
        value: 'http://localhost:3800'

  - name: node-renderer
    image: your-registry/myapp-node-renderer:latest # must include Node.js
    command: ['node', 'renderer/node-renderer.js']
    ports:
      - containerPort: 3800
    env:
      - name: RENDERER_HOST
        value: '0.0.0.0'
      - name: RENDERER_PORT
        value: '3800'
    startupProbe:
      tcpSocket:
        port: 3800
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 6
      timeoutSeconds: 1
    readinessProbe:
      # Omits initialDelaySeconds: startupProbe above defers readiness/liveness until boot succeeds (K8s 1.20+).
      # If you skip startupProbe or run an older cluster, add initialDelaySeconds to cover the boot window.
      # tcpSocket is a shallow fallback: port reachability only, not application readiness.
      tcpSocket:
        port: 3800
      periodSeconds: 10
      failureThreshold: 3
      timeoutSeconds: 1
    livenessProbe:
      # tcpSocket is port-open only; a hung event loop can still pass. For stricter hung-process
      # detection, use an exec probe with curl --http2-prior-knowledge and a short --max-time.
      tcpSocket:
        port: 3800
      periodSeconds: 10
      failureThreshold: 3
      timeoutSeconds: 1
```

> **Note:** `REACT_RENDERER_URL` must be read in your initializer for it to take effect:
>
> ```ruby
> # config/initializers/react_on_rails_pro.rb
> ReactOnRailsPro.configure do |config|
>   config.renderer_url = ENV["REACT_RENDERER_URL"]
> end
> ```

### Configuration for containers

When running the Node Renderer in containers:

- Set `host` to `0.0.0.0` so health checks and the Rails container can reach it. See [Node Renderer configuration](../building-features/node-renderer/js-configuration.md).
- On Control Plane, use `process.env.PORT` for the port — Control Plane assigns the port dynamically. See the [Control Plane port docs](https://docs.controlplane.com/reference/workload/containers#port-variable).
- Set `workersCount` explicitly rather than relying on CPU auto-detection, which can over-allocate workers in constrained containers.
- Use `tcpSocket` probes for shallow Kubernetes startup, readiness, and liveness checks. Kubernetes `httpGet` probes use HTTP/1.1 and cannot check the h2c-only Node Renderer listener directly.
- The manifest above uses portable `tcpSocket` checks. For application-level readiness, use an `exec` probe with an h2c-capable client packaged in the renderer image, or expose a separate HTTP/1.1 health endpoint in your own application code. See [Configuring Startup, Readiness, and Liveness Probes](../building-features/node-renderer/js-configuration.md#configuring-startup-readiness-and-liveness-probes) for timing values and `curl --http2-prior-knowledge` examples.

## Static assets and CDN

For all Docker deployments, choose one of:

1. **Rails serves static files** — Set `RAILS_SERVE_STATIC_FILES=true`. Simplest option, suitable for low-traffic apps.
2. **Reverse proxy serves files** — Nginx, Traefik, or a cloud load balancer serves files from `/public` directly.
3. **CDN** — Upload `public/webpack/production/` to a CDN and set `config.asset_host` in Rails. Best for global performance.

## Troubleshooting

### Assets missing at runtime

If styles or JS are missing after deploy, verify:

1. `assets:precompile` ran successfully during `docker build`
2. Client bundles exist in `public/webpack/production/` in the built image
3. `RAILS_SERVE_STATIC_FILES=true` is set if there is no external file server

```bash
# Check assets inside a running container
docker exec <container> ls public/webpack/production/
```

### Out of memory during build

Webpack/Rspack compilation can exceed default container memory. Solutions:

- Increase Docker builder memory: `docker build --memory=4g`
- Use a separate CI pipeline for image builds with higher resource limits
- With Kamal, use `builder.remote` to offload builds to a more powerful machine

### Server rendering fails

If SSR with ExecJS fails in the container but works locally:

1. Ensure `ssr-generated/server-bundle.js` exists in the image
2. Check that a JavaScript runtime is available. The Dockerfile above intentionally excludes Node from the runtime stage. If your app needs runtime JS execution (e.g. ExecJS), either add `mini_racer` to your Gemfile (no Node required) or install Node in the runtime stage. For high-performance SSR, consider the [Pro Node Renderer sidecar](#node-renderer-in-containers) instead.
3. Check logs: `RAILS_LOG_TO_STDOUT=true bundle exec rails console` and try `ReactOnRails::ServerRenderingPool.reset_pool`

## See also

- [Heroku Deployment](./heroku-deployment.md) — PaaS deployment without Docker
- [Configuration Reference](../configuration/README.md) — All React on Rails settings
- [Node Renderer Configuration](../building-features/node-renderer/js-configuration.md) — Pro Node Renderer setup
- [Server Rendering Tips](./server-rendering-tips.md) — SSR debugging and optimization
- [Control Plane Flow](https://github.com/shakacode/control-plane-flow/) — cpflow gem for Control Plane deployments
