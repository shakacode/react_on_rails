# frozen_string_literal: true

module ReactOnRailsPro
  # Module: LicensePublicKey
  #
  # Contains ShakaCode's public RSA key used for React on Rails Pro license verification.
  # The corresponding private key is securely held by ShakaCode and is never committed to the repository.
  #
  # You can update this public key by running the rake task:
  #   react_on_rails_pro:update_public_key
  # This task fetches the latest key from the API endpoint:
  #   http://shakacode.com/api/public-key
  #
  # TODO: Add a prepublish check to ensure this key matches the latest public key from the API.
  #       This should be implemented after publishing the API endpoint on the ShakaCode website.
  module LicensePublicKey
    # ShakaCode's public key for React on Rails Pro license verification
    # The private key corresponding to this public key is held by ShakaCode
    # and is never committed to the repository
    # Last updated: 2025-10-09 15:57:09 UTC
    # Source: http://shakacode.com/api/public-key
    KEY = OpenSSL::PKey::RSA.new(<<~PEM.strip.strip_heredoc)
      -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlJFK3aWuycVp9X05qhGo
FLztH8yjpuAKUoC4DKHX0fYjNIzwG3xwhLWKKDCmnNfuzW5R09/albl59/ZCHFyS
I7H7Aita1l9rnHCHEyyyJUs/E7zMG27lsECkNoCJr5cD/qtabY45uggFJrl3YRgy
ieonNQvxLtvPuatAPd6jfs/PlHOYA3z+t0C5uDW5YlXJkLKzKKiikvxsyOnk94Uq
J7FWzSdlvY08aLkERZDlGuWcjvQexVz7NCAMR050aEgobwxg2AuaCWDd8cDH6Asq
mhGxQr7ulvrXfDMI6dBqa3ihfjgk+dpA8ilfUsCFc8ovbIA0oE8BTIxogyYr2KaH
vQIDAQAB
-----END PUBLIC KEY-----
    PEM
  end
end
