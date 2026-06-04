# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RSC use-client CSS manifest regression" do
  let(:manifest_path) { Rails.root.join("public", "webpack", Rails.env, "react-client-manifest.json") }
  let(:probe_key_fragment) { "RSCPostsPage/UseClientCssProbe.jsx" }

  it "records CSS assets for use-client components rendered by an RSC page" do
    expect(File).to exist(manifest_path)

    manifest = JSON.parse(File.read(manifest_path))
    entries = manifest.fetch("filePathToModuleMetadata", manifest)
    _entry_key, metadata = entries.find { |key, _value| key.include?(probe_key_fragment) }

    expect(metadata).to be_present, "Expected #{probe_key_fragment} in #{manifest_path}"

    # The generated RSCManifestCssPlugin records the JS and CSS sibling chunks of
    # each 'use client' module so the renderer can load and preload them (see
    # #3211). Without the helper, CSS-first chunks can be skipped by the upstream
    # manifest scan.
    expect(metadata.fetch("chunks")).to include(a_string_matching(/\.js(?:\?|$)/))
    expect(metadata.fetch("css")).to include(a_string_matching(/\.css(?:\?|$)/))
  end
end
