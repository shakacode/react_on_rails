# Rolling-Deploy Adapters

> [!NOTE]
> **Summary for AI agents:** Use this page when the user is configuring a `rolling_deploy_adapter` to eliminate 410→retry cold starts for **previous** deployed bundle hashes during rolling deploys. The [Node Renderer page](./node-renderer.md) covers the current-hash pre-seeding (PR A) and unified copy/symlink staging (PR B); this page is specific to the rolling-deploy adapter protocol introduced alongside them.

## The problem

During a rolling deploy:

- Old Rails instances (bundle hash `abc`) are still draining traffic.
- New Rails instances (bundle hash `def`) serve new traffic.
- New renderer instances receive requests for **both** hashes.

Pre-seeding the current hash (`def`) eliminates the 410→retry only for the new bundle. Requests referencing `abc` still hit a cold cache on new renderers, producing 410 retries per request until the renderer has cached that bundle via upload.

The **`rolling_deploy_adapter`** protocol lets your application fetch previously-deployed bundles (and their companion assets) from an artifact store during the next build, so new renderer instances start warm for every in-flight bundle hash.

## The loadable-stats wrinkle

Each bundle hash has **companion assets** built in lockstep:

- `loadable-stats.json` — maps chunk IDs → asset URLs.
- `react-client-manifest.json`, `react-server-client-manifest.json` (when RSC enabled) — map component IDs → chunk paths.

If the renderer handles a request for bundle `abc` but reads the **new** build's manifests, it emits HTML referencing chunk URLs that the old deployment's asset pipeline never produced → client-side hydration breakage, chunk 404s.

**Therefore: each seeded bundle hash must carry its own companion assets.** The adapter's `fetch(hash)` method returns bundle + assets together so the caller can't forget.

## Protocol

Your adapter must define three class methods:

```ruby
module MyRollingDeployAdapter
  # Discovery. Called during pre-seeding to determine which historical
  # hashes to fetch. Typically hits the running deployment's /_health
  # endpoint or reads a manifest file in the artifact store.
  # @return [Array<String>] ordered list of recent bundle hashes.
  # @return [] to disable previous-bundle seeding on this build.
  def self.previous_bundle_hashes
    # ...
  end

  # Retrieval. Given a bundle hash, fetch the bundle + its companion
  # assets to local disk and return their paths.
  # @return [Hash, nil] Hash with :server_bundle (required), :rsc_bundle
  #   (optional), :assets (Array<String>). nil if unavailable — pre-seeding
  #   logs a warning and continues.
  def self.fetch(bundle_hash)
    # ...
  end

  # Publication. Called automatically after assets:precompile in
  # production-like environments when the adapter is configured.
  # Uploads the current build's bundle + assets keyed by hash so
  # future deploys can retrieve them. Errors are warned, not raised.
  def self.upload(bundle_hash, server_bundle:, rsc_bundle: nil, assets:)
    # ...
  end
end

# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.rolling_deploy_adapter = MyRollingDeployAdapter
end
```

## Env-var override

For CI and testing, set `PREVIOUS_BUNDLE_HASHES` as a comma-separated list to skip `previous_bundle_hashes` discovery:

```bash
PREVIOUS_BUNDLE_HASHES=abc123,def456 rake react_on_rails_pro:pre_seed_renderer_cache
```

This runs the adapter's `fetch(hash)` for each listed hash but skips discovery.

## Edge cases and error handling

| Scenario                               | Behavior                                                                     |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| Adapter not configured                 | No-op. Only the current hash is staged.                                      |
| `previous_bundle_hashes` returns `[]`  | Log "No previous bundle hashes to seed" and continue.                        |
| `previous_bundle_hashes` raises        | Warn, skip previous-hash seeding, continue. Current-hash staging unaffected. |
| `fetch(hash)` returns `nil`            | Warn, skip that hash. Runtime 410-retry remains the fallback.                |
| `fetch(hash)` raises                   | Warn, skip that hash. Runtime 410-retry remains the fallback.                |
| Returned hash matches current hash     | Deduplicated — not refetched.                                                |
| `upload` raises in `assets:precompile` | Warn but don't fail precompile. Next deploy degrades, not this one.          |

## Reference implementations

These are copy-pasteable starting points. Adapt to your infrastructure.

### S3

Publish bundles + companion assets under `s3://<bucket>/bundles/<hash>/`. A manifest file at `bundles/_manifest.json` tracks the rolling list of recent hashes.

```ruby
require "aws-sdk-s3"
require "fileutils"
require "json"

class S3RollingDeployAdapter
  BUCKET = ENV.fetch("ROLLING_DEPLOY_BUCKET")
  PREFIX = "bundles"
  MANIFEST_KEY = "#{PREFIX}/_manifest.json".freeze
  RETENTION = 3

  def self.previous_bundle_hashes
    resp = s3.get_object(bucket: BUCKET, key: MANIFEST_KEY)
    JSON.parse(resp.body.read).fetch("hashes", []).last(RETENTION)
  rescue Aws::S3::Errors::NoSuchKey
    []
  end

  def self.fetch(hash)
    dir = Rails.root.join("tmp/rolling-deploy", hash)
    FileUtils.mkdir_p(dir)
    {
      server_bundle: download_to(dir, "server-bundle.js", hash),
      rsc_bundle: download_optional(dir, "rsc-bundle.js", hash),
      assets: %w[loadable-stats.json react-client-manifest.json react-server-client-manifest.json]
              .map { |name| download_optional(dir, name, hash) }
              .compact
    }
  rescue Aws::S3::Errors::NoSuchKey
    nil
  end

  def self.upload(hash, server_bundle:, rsc_bundle: nil, assets:)
    put("#{PREFIX}/#{hash}/server-bundle.js", server_bundle)
    put("#{PREFIX}/#{hash}/rsc-bundle.js", rsc_bundle) if rsc_bundle
    assets.each { |path| put("#{PREFIX}/#{hash}/#{File.basename(path)}", path) }
    update_manifest!(hash)
  end

  # -- helpers (private by convention) --

  def self.s3
    @s3 ||= Aws::S3::Client.new
  end

  def self.download_to(dir, name, hash)
    path = dir.join(name).to_s
    s3.get_object(bucket: BUCKET, key: "#{PREFIX}/#{hash}/#{name}", response_target: path)
    path
  end

  def self.download_optional(dir, name, hash)
    download_to(dir, name, hash)
  rescue Aws::S3::Errors::NoSuchKey
    nil
  end

  def self.put(key, path)
    File.open(path, "rb") { |body| s3.put_object(bucket: BUCKET, key: key, body: body) }
  end

  def self.update_manifest!(hash)
    hashes = previous_bundle_hashes
    hashes << hash unless hashes.include?(hash)
    s3.put_object(
      bucket: BUCKET,
      key: MANIFEST_KEY,
      body: JSON.generate(hashes: hashes.last(RETENTION + 1))
    )
  end
end
```

### Control Plane

Uses `cpln` CLI to pull the previous deployment's image layer and extract cache contents. `upload` is a no-op — the image itself is the artifact.

```ruby
class ControlPlaneRollingDeployAdapter
  GVC = ENV.fetch("CPLN_GVC")
  WORKLOAD = ENV.fetch("CPLN_RAILS_WORKLOAD")

  def self.previous_bundle_hashes
    output = `cpln workload get #{WORKLOAD} --gvc #{GVC} -o json`
    env = JSON.parse(output).dig("spec", "containers", 0, "env") || []
    hash = env.find { |e| e["name"] == "REACT_ON_RAILS_BUNDLE_HASH" }&.dig("value")
    hash ? [hash] : []
  end

  def self.fetch(hash)
    image = "#{GVC}/app-#{hash}"
    tmp = Rails.root.join("tmp/rolling-deploy", hash)
    FileUtils.mkdir_p(tmp)
    # Extract cache dir contents from the previous image layer:
    system("cpln image pull #{image} --output #{tmp}") or return nil
    { server_bundle: tmp.join("server-bundle.js").to_s,
      rsc_bundle: File.exist?(tmp.join("rsc-bundle.js")) ? tmp.join("rsc-bundle.js").to_s : nil,
      assets: Dir[tmp.join("*.json")] }
  end

  def self.upload(_hash, server_bundle:, rsc_bundle: nil, assets:)
    # No-op: the Docker image IS the artifact. The next build pulls
    # via `cpln image pull`.
  end
end
```

### Filesystem (testing / volume-mounted deploys)

Reads/writes a local directory specified by `ROLLING_DEPLOY_DIR`. Useful for local experimentation and as the reference test fixture.

```ruby
require "fileutils"
require "json"

class FilesystemRollingDeployAdapter
  def self.root
    Pathname.new(ENV.fetch("ROLLING_DEPLOY_DIR"))
  end

  def self.previous_bundle_hashes
    manifest = root.join("_manifest.json")
    return [] unless manifest.exist?

    JSON.parse(manifest.read).fetch("hashes", [])
  end

  def self.fetch(hash)
    dir = root.join(hash)
    return nil unless dir.directory?

    { server_bundle: dir.join("server-bundle.js").to_s,
      rsc_bundle: (dir.join("rsc-bundle.js").to_s if dir.join("rsc-bundle.js").exist?),
      assets: Dir[dir.join("*.json")] }
  end

  def self.upload(hash, server_bundle:, rsc_bundle: nil, assets:)
    dir = root.join(hash)
    FileUtils.mkdir_p(dir)
    FileUtils.cp(server_bundle, dir.join("server-bundle.js"))
    FileUtils.cp(rsc_bundle, dir.join("rsc-bundle.js")) if rsc_bundle
    assets.each { |p| FileUtils.cp(p, dir.join(File.basename(p))) }
    hashes = (previous_bundle_hashes + [hash]).uniq
    root.join("_manifest.json").write(JSON.generate(hashes: hashes))
  end
end
```

## Verifying your adapter with `react_on_rails:doctor`

`react_on_rails:doctor` probes a configured `rolling_deploy_adapter` and reports:

- ✅ Whether it responds to all three required methods.
- ✅ Whether `previous_bundle_hashes` returns successfully within 3 seconds, and how many hashes it returned.
- ⚠️ Empty-list returns (often indicates the upload side has never run on a prior deploy).
- ℹ️ The resolved renderer cache dir and how many bundle-hash subdirectories are present.
- ℹ️ Whether `PREVIOUS_BUNDLE_HASHES` env override is set.

Doctor never calls `fetch` or `upload` — those have side effects.

## Relationship to `remote_bundle_cache_adapter`

These two adapters solve different problems and are complementary:

|              | `remote_bundle_cache_adapter`                 | `rolling_deploy_adapter`                  |
| ------------ | --------------------------------------------- | ----------------------------------------- |
| **Scope**    | Webpack build outputs (pre-compile caching)   | Deployed bundle hashes (rolling deploy)   |
| **When**     | Build phase (`assets:precompile`)             | Post-precompile + pre-seed phase          |
| **Avoids**   | Rebuilding webpack when source hasn't changed | 410 retries for draining-version requests |
| **Keyed by** | Source digest                                 | Bundle hash                               |

You can configure both; they don't interact.
