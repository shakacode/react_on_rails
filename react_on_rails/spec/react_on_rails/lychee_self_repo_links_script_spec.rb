# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require_relative "spec_helper"

RSpec.describe "bin/lychee-self-repo-links" do
  let(:repo_root) { File.expand_path("../../..", __dir__) }
  let(:script_path) { File.join(repo_root, "bin/lychee-self-repo-links") }
  let(:self_repo) { "https://github.com/shakacode/react_on_rails" }

  it "rewrites links to files on main or master into file URLs inside the checkout" do
    with_checkout do |checkout|
      output = preprocess(checkout, <<~MARKDOWN)
        [blob](#{self_repo}/blob/main/react_on_rails_pro/lib/react_on_rails_pro/utils.rb)
        [tree](#{self_repo}/tree/main/docs/oss)
        [root](#{self_repo}/tree/main)
        [lines](#{self_repo}/blob/main/react_on_rails_pro/spec/dummy/config/webpack/commonWebpackConfig.js#L41-L49)
        [plain](#{self_repo}/blob/main/README.md?plain=1)
        <#{self_repo}/blob/main/CONTRIBUTING.md>
        [master](#{self_repo}/blob/master/react_on_rails/spec/dummy/spec/rails_helper.rb#L36..38)
        [ref]: #{self_repo}/blob/main/internal/adr/0001-rspack-answers-vite.md
      MARKDOWN

      expect(output).to eq(<<~MARKDOWN)
        [blob](file://#{checkout}/react_on_rails_pro/lib/react_on_rails_pro/utils.rb)
        [tree](file://#{checkout}/docs/oss)
        [root](file://#{checkout})
        [lines](file://#{checkout}/react_on_rails_pro/spec/dummy/config/webpack/commonWebpackConfig.js#L41-L49)
        [plain](file://#{checkout}/README.md?plain=1)
        <file://#{checkout}/CONTRIBUTING.md>
        [master](file://#{checkout}/react_on_rails/spec/dummy/spec/rails_helper.rb#L36..38)
        [ref]: file://#{checkout}/internal/adr/0001-rspack-answers-vite.md
      MARKDOWN
    end
  end

  it "leaves other refs, pages, and repositories on GitHub" do
    markdown = <<~MARKDOWN
      [tag](#{self_repo}/tree/15.0.0/docs)
      [commit](#{self_repo}/blob/b3d30a15c/docs/oss/deployment/capistrano-deployment.md)
      [similar branch](#{self_repo}/blob/main-2/README.md)
      [prefix branch](#{self_repo}/tree/maintenance/docs)
      [master prefix branch](#{self_repo}/tree/master-2/docs)
      [pull request](#{self_repo}/pull/5185)
      [other repo](https://github.com/shakacode/shakapacker/blob/main/README.md)
      [similar repo](https://github.com/shakacode/react_on_rails_pro/blob/main/README.md)
    MARKDOWN

    with_checkout do |checkout|
      expect(preprocess(checkout, markdown)).to eq(markdown)
    end
  end

  it "passes other content through byte for byte" do
    markdown = "# Überblick\r\nSee [docs](https://reactonrails.com/docs).\r\nNo newline at end"

    with_checkout do |checkout|
      expect(preprocess(checkout, markdown).b).to eq(markdown.b)
    end
  end

  it "percent-encodes a checkout path that is not URL-safe" do
    with_checkout("react on#rails") do |checkout|
      encoded_checkout = File.join(File.dirname(checkout), "react%20on%23rails")

      expect(preprocess(checkout, "[docs](#{self_repo}/tree/main/docs)\n"))
        .to eq("[docs](file://#{encoded_checkout}/docs)\n")
    end
  end

  it "fails when the input cannot be read" do
    Dir.mktmpdir do |tmpdir|
      stdout, stderr, status = Open3.capture3(script_path, "missing.md", chdir: tmpdir)

      expect(status).not_to be_success
      expect(stdout).to be_empty
      expect(stderr).to include("cannot read missing.md")
    end
  end

  # Runs a copy of the script from bin/ in a temporary checkout, which is what the
  # script resolves its file:// URLs against.
  def with_checkout(name = "checkout")
    Dir.mktmpdir do |tmpdir|
      checkout = File.join(File.realpath(tmpdir), name)
      FileUtils.mkdir_p(File.join(checkout, "bin"))
      FileUtils.cp(script_path, File.join(checkout, "bin"), preserve: true)
      yield checkout
    end
  end

  def preprocess(checkout, markdown)
    input_path = File.join(checkout, "input.md")
    File.binwrite(input_path, markdown)
    stdout, stderr, status = Open3.capture3(File.join(checkout, "bin/lychee-self-repo-links"), input_path)

    expect(status).to be_success, stderr
    stdout
  end
end
