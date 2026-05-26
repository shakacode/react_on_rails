# frozen_string_literal: true

module ReactOnRailsPro
  module RollingDeploy
    # Path-safety regex shared by the rolling-deploy cache stager, the bundles
    # controller route constraint, and the HTTP adapter. Rejects empty strings,
    # leading dots, path separators, `..`, and anything outside a flat
    # alphanumeric basename plus `_`, `.`, and `-`.
    SAFE_HASH_PATTERN = /\A(?!\.)[A-Za-z0-9_.\-]+\z/
  end
end
