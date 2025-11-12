# frozen_string_literal: true

# Local test configuration for Conductor workspaces
# This file is gitignored and contains environment-specific workarounds

# Disable webdrivers auto-update to avoid SSL issues in Conductor environment
require "webdrivers"
Webdrivers.cache_time = 86_400 * 365 # Cache for 1 year (effectively disable updates)

# Disable SSL verification globally for tests (Conductor environment workaround)
# WARNING: This is a security risk and should ONLY be used in isolated test environments
require "openssl"
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
