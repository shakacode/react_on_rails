# frozen_string_literal: true

require "minitest/autorun"
require "rbconfig"
require_relative "pr_merge_ledger_test_helpers"
load SCRIPT unless defined?(PrMergeLedger)

class PrMergeLedgerScreenedReaderTest < Minitest::Test
  include PrMergeLedgerFixtureHelpers

  HEAD = "a" * 40
  URL = "https://github.com/shakacode/react_on_rails/pull/5182#issuecomment-1"

  def packet
    {
      "head" => HEAD,
      "trust_sources" => [{ "scope" => "repository", "sha256" => "b" * 64 }],
      "issue_comments" => [{ "url" => URL, "author" => "maintainer", "body" => "P1: fix this" }],
      "review_summaries" => [], "inline_comments" => [], "excluded_interactions" => []
    }
  end

  def metadata(url: URL, author: "maintainer")
    { "url" => url, "author" => { "login" => author }, "id" => "node-id" }
  end

  def test_collector_omits_bodies_from_every_comment_query_but_keeps_pr_body
    collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails",
                                                   shaka_reader: "/trusted/shaka", trusted_ref: HEAD)
    %i[review_threads_query review_thread_comments_query reviews_query comments_query].each do |method|
      refute_match(/^\s*body\s*$/, collector.send(:comment_query, collector.send(method)))
    end
    assert_match(/^\s*body\s*$/, collector.send(:metadata_query))
  end

  def test_trusted_body_is_reconciled_with_live_metadata
    reader = ShakaScreenedComments.new(packet, HEAD)
    rows = [metadata]
    reader.apply!(rows, "issue_comments")
    reader.verify_complete!
    assert_equal "P1: fix this", rows.first.fetch("body")
    assert_equal 64, reader.provenance.fetch("packet_sha256").length
  end

  def test_help_states_that_withheld_text_is_not_scanned
    help = PrMergeLedger.new([]).send(:build_option_parser).help
    assert_match(/withholds is not scanned for findings or \+ci commands/, help)
  end

  def test_excluded_body_is_not_required_and_metadata_is_preserved
    data = packet
    data["issue_comments"] = []
    [true, false].each do |body_withheld|
      data["excluded_interactions"] = [{ "url" => URL, "kind" => "issue_comment", "author" => "maintainer",
                                         "body_withheld" => body_withheld, "verification_unavailable" => false }]
      reader = ShakaScreenedComments.new(data, HEAD)
      rows = [metadata]
      reader.apply!(rows, "issue_comments")
      reader.verify_complete!
      refute rows.first.key?("body")
      assert_equal "node-id", rows.first.fetch("id")
      assert_equal 1, reader.provenance.fetch("withheld_count")
    end
  end

  def test_changed_head_missing_screening_and_actor_mismatch_fail_closed
    assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(packet, "c" * 40) }
    reader = ShakaScreenedComments.new(packet, HEAD)
    assert_raises(PrMergeLedger::Error) { reader.apply!([metadata(url: "new-comment")], "issue_comments") }
    assert_raises(PrMergeLedger::Error) { reader.apply!([metadata(author: "other")], "issue_comments") }
  end

  def test_missing_trusted_metadata_or_duplicate_screening_fails_closed
    reader = ShakaScreenedComments.new(packet, HEAD)
    assert_raises(PrMergeLedger::Error) { reader.verify_complete! }
    data = packet
    data["issue_comments"] *= 2
    assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD) }
  end

  def test_unavailable_screening_and_unscreened_body_fail_closed
    data = packet
    data["issue_comments"] = []
    data["excluded_interactions"] = [{ "url" => URL, "kind" => "issue_comment", "author" => "maintainer",
                                       "body_withheld" => true, "verification_unavailable" => true }]
    assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD) }
    data["excluded_interactions"].first["body_withheld"] = false
    assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD) }
    data["excluded_interactions"].first["verification_unavailable"] = false
    [nil, "false"].each do |flag|
      data["excluded_interactions"].first["body_withheld"] = flag
      assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD) }
    end
    reader = ShakaScreenedComments.new(packet, HEAD)
    assert_raises(PrMergeLedger::Error) { reader.apply!([metadata.merge("body" => "raw")], "issue_comments") }
  end

  def test_bot_suffix_requires_github_bot_type
    data = packet
    data["issue_comments"].first["author"] = "reviewer[bot]"
    reader = ShakaScreenedComments.new(data, HEAD)
    row = metadata(author: "reviewer")
    row["author"]["__typename"] = "Bot"
    reader.apply!([row], "issue_comments")
    reader.verify_complete!
    assert_equal "P1: fix this", row.fetch("body")
    row = metadata(author: "reviewer")
    row["author"]["__typename"] = "User"
    assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD).apply!([row], "issue_comments") }
  end

  def test_withheld_changes_requested_review_still_blocks_the_ledger
    data = packet
    data["issue_comments"] = []
    data["excluded_interactions"] = [{ "kind" => "review_summary", "url" => URL,
                                       "author" => "maintainer", "body_withheld" => true,
                                       "verification_unavailable" => false }]
    reader = ShakaScreenedComments.new(data, HEAD)
    rows = [metadata.merge("state" => "CHANGES_REQUESTED", "commit" => { "oid" => HEAD },
                           "submittedAt" => "2026-10-15T00:00:00Z")]
    reader.apply!(rows, "review_summaries")
    reader.verify_complete!
    dataset = fixture_with_body("No linked issue.")
    dataset["pull_request"]["headRefOid"] = HEAD
    dataset["reviews"] = rows
    stdout, status = run_fixture(dataset)
    refute status.success?
    assert_includes violation_codes(JSON.parse(stdout)), "changes_requested_review_object"
  end

  def test_push_during_screened_collection_is_rejected
    collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails")
    collector.define_singleton_method(:graphql) do |_query, _variables|
      { "data" => { "repository" => { "pullRequest" => { "headRefOid" => "c" * 40 } } } }
    end
    assert_raises(PrMergeLedger::Error) { collector.send(:verify_screened_head!, 5182, HEAD) }
  end
end

# Reader edge cases, and GitHubCollector#fetch run end to end with the reader and GitHub calls replaced.
class PrMergeLedgerScreenedCollectionTest < Minitest::Test
  HEAD = PrMergeLedgerScreenedReaderTest::HEAD
  URL = PrMergeLedgerScreenedReaderTest::URL

  def packet = PrMergeLedgerScreenedReaderTest.new(nil).packet

  def metadata(...) = PrMergeLedgerScreenedReaderTest.new(nil).metadata(...)

  def test_deleted_account_comment_is_matched_as_ghost
    data = packet
    data["issue_comments"] = [{ "url" => URL, "author" => "ghost", "body" => "old note" }]
    reader = ShakaScreenedComments.new(data, HEAD)
    rows = [{ "url" => URL, "author" => nil, "id" => "node-id" }]
    reader.apply!(rows, "issue_comments")
    reader.verify_complete!
    assert_equal "old note", rows.first.fetch("body")
  end

  def test_empty_body_review_listed_by_the_reader_passes
    data = packet
    data["issue_comments"] = []
    review_url = "https://github.com/shakacode/react_on_rails/pull/5182#pullrequestreview-1"
    data["review_summaries"] = [{ "url" => review_url, "author" => "maintainer", "body" => "" }]
    reader = ShakaScreenedComments.new(data, HEAD)
    rows = [metadata(url: review_url).merge("state" => "COMMENTED")]
    reader.apply!(rows, "review_summaries")
    reader.verify_complete!
    assert_equal "", rows.first.fetch("body")
  end

  def test_malformed_packet_fails_with_ledger_error
    [
      packet.merge("issue_comments" => nil),
      packet.merge("review_summaries" => {}),
      packet.merge("inline_comments" => ["not an object"]),
      packet.merge("excluded_interactions" => nil),
      packet.merge("excluded_interactions" => [42])
    ].each do |data|
      assert_raises(PrMergeLedger::Error) { ShakaScreenedComments.new(data, HEAD) }
    end
  end

  def test_screened_collection_records_provenance_when_head_is_stable
    collector = screened_collector(push_during_ci: false)
    data = with_reader_packet { collector.fetch(5182) }
    assert_equal "P1: fix this", data.fetch("comments").first.fetch("body")
    provenance = collector.screened_collections.first
    assert_equal({ "pr" => 5182, "reader" => "shaka", "head" => HEAD },
                 provenance.slice("pr", "reader", "head"))
    assert_equal 0, provenance.fetch("withheld_count")
  end

  def test_push_during_ci_collection_rejects_screened_comments
    collector = screened_collector(push_during_ci: true)
    error = assert_raises(PrMergeLedger::Error) { with_reader_packet { collector.fetch(5182) } }
    assert_match(/head changed during screened collection/, error.message)
    assert_empty collector.screened_collections
  end

  def test_reader_failure_reports_exit_status_and_reason
    collector = screened_collector(push_during_ci: false)
    collector.define_singleton_method(:fetch_ci_readiness) { |*_args, **_options| raise "collection continued" }
    failed = Struct.new(:success?, :exitstatus).new(false, 3)
    stderr = "shaka: GitHub rate limit exceeded\n#{'x' * 500}\nsecond line"
    calls = []
    error = assert_raises(PrMergeLedger::Error) do
      stub_reader(["", stderr, failed], on_call: ->(args) { calls << args }) { collector.fetch(5182) }
    end
    assert_equal "Shaka screened comment reader failed (exit 3): shaka: GitHub rate limit exceeded", error.message
    args = calls.fetch(0)
    assert_equal ["/trusted/shaka", "comments", "shakacode/react_on_rails", "5182"], args.first(4)
    assert_equal [HEAD, HEAD], [args[args.index("--head") + 1], args[args.index("--ref") + 1]]
  end

  def test_unparseable_reader_output_is_a_ledger_error
    collector = screened_collector(push_during_ci: false)
    error = assert_raises(PrMergeLedger::Error) do
      stub_reader(["not json", "", Struct.new(:success?, :exitstatus).new(true, 0)]) { collector.fetch(5182) }
    end
    assert_equal "Shaka screened comment reader returned invalid JSON", error.message
  end

  # Reading the packet last means a comment edited during collection carries its newer text,
  # and a comment added during collection appears only in the packet and fails closed.
  def test_reader_runs_after_the_live_comment_reads
    collector = screened_collector(push_during_ci: false)
    order = []
    %i[fetch_review_threads fetch_reviews fetch_comments].each do |method|
      previous = collector.method(method)
      collector.define_singleton_method(method) do |number|
        order << method
        previous.call(number)
      end
    end
    with_reader_packet(on_call: -> { order << :reader }) { collector.fetch(5182) }
    assert_equal %i[fetch_review_threads fetch_reviews fetch_comments reader], order
  end

  def test_comment_added_after_the_live_reads_fails_closed
    collector = screened_collector(push_during_ci: false)
    late = { "url" => "#{URL}2", "author" => "maintainer", "body" => "P1: added late" }
    data = packet.merge("issue_comments" => packet.fetch("issue_comments") + [late])
    error = assert_raises(PrMergeLedger::Error) { with_reader_packet(data) { collector.fetch(5182) } }
    assert_equal "screened interactions do not match live metadata", error.message
  end

  private

  # A collector whose GitHub calls return body-free rows; CI collection can simulate a push.
  def screened_collector(push_during_ci:)
    collector = PrMergeLedger::GitHubCollector.new("shakacode", "react_on_rails",
                                                   shaka_reader: "/trusted/shaka", trusted_ref: HEAD)
    state = { pushed: false }
    collector.define_singleton_method(:fetch_metadata_and_files) { |_number| [{ "headRefOid" => HEAD }, []] }
    collector.define_singleton_method(:fetch_labels) { |_number| [] }
    collector.define_singleton_method(:fetch_review_threads) { |_number| [] }
    collector.define_singleton_method(:fetch_reviews) { |_number| [] }
    collector.define_singleton_method(:fetch_comments) do |_number|
      [{ "url" => URL, "author" => { "login" => "maintainer" } }]
    end
    collector.define_singleton_method(:fetch_ci_readiness) do |_number, **_options|
      state[:pushed] = push_during_ci
      {}
    end
    collector.define_singleton_method(:graphql) do |_query, _variables|
      head = state[:pushed] ? "c" * 40 : HEAD
      { "data" => { "repository" => { "pullRequest" => { "headRefOid" => head } } } }
    end
    collector
  end

  def with_reader_packet(data = packet, on_call: nil, &)
    ok = Struct.new(:success?, :exitstatus).new(true, 0)
    stub_reader([JSON.generate(data), "", ok], on_call: on_call && ->(_args) { on_call.call }, &)
  end

  def stub_reader(result, on_call: nil)
    original = PrMergeLedger.method(:capture_command_with_timeout)
    PrMergeLedger.define_singleton_method(:capture_command_with_timeout) do |args, **_options|
      on_call&.call(args)
      result
    end
    yield
  ensure
    PrMergeLedger.define_singleton_method(:capture_command_with_timeout, original)
  end
end

class PrMergeLedgerScreenedReaderPathTest < Minitest::Test
  HEAD = "a" * 40

  def test_invalid_reader_options_fail_before_live_collection
    [
      ["--shaka-reader", SCRIPT, "--trusted-ref", HEAD],
      ["--shaka-reader", RbConfig.ruby, "--trusted-ref", "main"],
      ["--shaka-reader", "/tmp", "--trusted-ref", HEAD],
      ["--fixture", "unused.json", "--shaka-reader", RbConfig.ruby, "--trusted-ref", HEAD]
    ].each do |arguments|
      assert_raises(PrMergeLedger::Error) { PrMergeLedger.new(arguments).send(:parse_options) }
    end
  end

  def test_reader_symlink_is_pinned_before_metadata_collection
    Dir.mktmpdir("screened-reader") do |dir|
      reader = File.join(dir, "shaka")
      File.symlink(RbConfig.ruby, reader)
      app = PrMergeLedger.new(["5182", "--shaka-reader", reader, "--trusted-ref", HEAD])
      app.send(:parse_options)
      selected = app.instance_variable_get(:@options).fetch(:shaka_reader)
      File.unlink(reader)
      File.symlink(SCRIPT, reader)
      assert_equal File.realpath(RbConfig.ruby), selected
      refute_equal File.realpath(reader), selected
    end
  end

  def test_reader_resolution_cannot_be_retargeted_between_check_and_pin
    Dir.mktmpdir("screened-reader-race") do |dir|
      reader = File.join(dir, "shaka")
      File.symlink(RbConfig.ruby, reader)
      original = File.method(:realpath)
      resolutions = 0
      File.define_singleton_method(:realpath) do |path, *arguments|
        resolved = original.call(path, *arguments)
        if path == reader
          resolutions += 1
          if resolutions == 1
            File.unlink(reader)
            File.symlink(SCRIPT, reader)
          end
        end
        resolved
      end
      begin
        app = PrMergeLedger.new(["5182", "--shaka-reader", reader, "--trusted-ref", HEAD])
        app.send(:parse_options)
      ensure
        File.define_singleton_method(:realpath, original)
      end
      assert_equal original.call(RbConfig.ruby), app.instance_variable_get(:@options).fetch(:shaka_reader)
      assert_equal 1, resolutions
    end
  end

  def test_checkout_helper_is_rejected_when_running_from_a_subdirectory
    Dir.chdir(File.join(PrMergeLedger::CHECKOUT_ROOT, "react_on_rails")) do
      app = PrMergeLedger.new(["5182", "--shaka-reader", SCRIPT, "--trusted-ref", HEAD])
      assert_raises(PrMergeLedger::Error) { app.send(:parse_options) }
    end
  end
end
