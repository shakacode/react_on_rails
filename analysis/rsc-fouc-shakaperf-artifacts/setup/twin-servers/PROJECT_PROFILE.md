# Twin-server project profile

- Stack: React on Rails monorepo, Pro dummy Rails app at `react_on_rails_pro/spec/dummy`, SQLite test database, RSC node renderer.
- Runtime versions: Ruby 3.3.7, Node 22.12.0, pnpm 10.33.4.
- Server processes: Rails on container port 3000; node renderer on container port 3800.
- Backing services: SQLite only, prepared during image build with `RAILS_ENV=test bundle exec rails db:prepare`.
- Build steps baked into image: root `bundle install`, root `pnpm install --frozen-lockfile`, root `pnpm run build`, dummy pack generation, dummy `pnpm run build:test`, dummy test DB prepare.
- RSC route note: `RSCPostsPageOverHTTP` fetches `http://localhost:3000/api/posts`; this works inside each twin-server container because Rails binds to container-local port 3000.
