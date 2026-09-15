#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit tests for pr-ci-readiness.
# Run with: ruby .agents/skills/pr-batch/bin/pr-ci-readiness-test.rb

require "minitest/autorun"
require "open3"
require "json"
require "tmpdir"
require "fileutils"

SCRIPT = File.expand_path("pr-ci-readiness", __dir__)
load SCRIPT

class PrCiReadinessTest < Minitest::Test
  # --- Pure verdict logic (module_function), tested directly ---------------

  def test_all_passing_is_ready
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "examples", "bucket" => "skipping" }
                               ])
    assert_equal "READY", out["verdict"]
    assert_equal true, out["required_used"]
    assert_empty out["failing"]
    assert_empty out["pending"]
  end

  def test_failing_is_not_ready_with_name_surfaced
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "lint", "bucket" => "fail" }
                               ])
    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["lint"], out["failing"]
    assert_empty out["pending"]
  end

  def test_pending_is_not_ready
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "name" => "rspec", "bucket" => "pass" },
                                 { "name" => "build", "bucket" => "pending" }
                               ])
    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["build"], out["pending"]
  end

  def test_empty_rows_is_unknown
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [])
    assert_equal "UNKNOWN", out["verdict"]
  end

  def test_cancel_only_is_unknown
    out = PrCiReadiness.assess(pr_number: 1, required_used: false,
                               rows: [{ "name" => "stale", "bucket" => "cancel" }])
    assert_equal "UNKNOWN", out["verdict"]
  end

  def test_same_context_current_pass_supersedes_cancelled_history
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "workflow" => "CI", "name" => "rspec", "bucket" => "pass" },
                                 { "workflow" => "CI", "name" => "rspec", "bucket" => "cancel" }
                               ])
    assert_equal "READY", out["verdict"]
    assert_empty out["failing"]
    assert_empty out["pending"]
  end

  def test_distinct_cancelled_required_context_is_not_ready_with_name_surfaced
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "workflow" => "CI", "name" => "unit", "bucket" => "pass" },
                                 { "workflow" => "Security", "name" => "security", "bucket" => "cancel" }
                               ])

    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["security"], out["pending"]
  end

  def test_same_name_in_different_workflow_does_not_supersede_cancelled_required_context
    out = PrCiReadiness.assess(pr_number: 1, required_used: true, rows: [
                                 { "workflow" => "CI", "name" => "unit", "bucket" => "pass" },
                                 { "workflow" => "Security", "name" => "unit", "bucket" => "cancel" }
                               ])

    assert_equal "NOT_READY", out["verdict"]
    assert_equal ["unit"], out["pending"]
  end

  def test_cancel_row_dropped_from_failing_and_pending
    out = PrCiReadiness.assess(pr_number: 1, required_used: false, rows: [
                                 { "name" => "lint", "bucket" => "fail" },
                                 { "name" => "stale", "bucket" => "cancel" }
                               ])
    assert_equal ["lint"], out["failing"]
    assert_equal "NOT_READY", out["verdict"]
  end

  # --- parse helpers --------------------------------------------------------

  def test_usable_checks_discriminates_payloads
    assert PrCiReadiness.usable_checks?('[{"name":"a","bucket":"pass"}]')
    refute PrCiReadiness.usable_checks?("[]")
    refute PrCiReadiness.usable_checks?("")
    refute PrCiReadiness.usable_checks?(nil)
    refute PrCiReadiness.usable_checks?("no required checks") # non-JSON message
    # Cancel-only rows are not usable: they must not short-circuit the fallback.
    refute PrCiReadiness.usable_checks?('[{"name":"stale","bucket":"cancel"}]')
  end

  def test_parse_rows_handles_non_array_json
    assert_equal [], PrCiReadiness.parse_rows('{"oops":true}')
  end

  def test_text_summary_format
    out = PrCiReadiness.assess(pr_number: 9, required_used: true, rows: [
                                 { "name" => "lint", "bucket" => "fail" }
                               ])
    text = PrCiReadiness.text_summary(out)
    assert_includes text, "NOT_READY"
    assert_includes text, "required_used: true"
    assert_includes text, "failing: lint"
    assert_includes text, "pending: (none)"
  end

  def test_text_summary_labels_review_drafts_as_authenticated_viewer_scoped
    text = PrCiReadiness.text_summary(
      "verdict" => "NOT_READY",
      "required_used" => true,
      "failing" => [],
      "pending" => [],
      "viewer_pending_review_drafts" => [{ "id" => "PRR_one" }],
      "viewer_review_inventory" => { "scope" => "authenticated_viewer", "complete" => true }
    )

    assert_includes text, "viewer_pending_review_drafts: PRR_one"
    assert_includes text, "viewer_review_inventory: complete (scope: authenticated_viewer)"
  end

  def test_usage_describes_authenticated_viewer_scope_and_unobservable_drafts
    assert_includes PrCiReadiness::USAGE, "visible to the current authenticated"
    assert_includes PrCiReadiness::USAGE, "Other reviewers'"
    assert_includes PrCiReadiness::USAGE, '"viewer_pending_review_drafts"'
    assert_includes PrCiReadiness::USAGE, '"scope": "authenticated_viewer"'
  end
end

# CLI / Runner integration via a fake gh on PATH.
class PrCiReadinessCliTest < Minitest::Test
  # Build a temp dir with a fake `gh` executable that emits canned `gh pr
  # checks` JSON, then run the real script with that dir prepended to PATH.
  def with_fake_gh(required_json:, full_json:, pr_head: "head-sha", runs: {}, review_pages: {}, review_error: false,
                   required_check_fields: nil, rejected_check_field: nil, check_stderr: nil, check_status: 0,
                   required_check_error: nil, full_check_error: nil)
    Dir.mktmpdir("pr-ci-readiness-test") do |dir|
      gh = File.join(dir, "gh")
      File.write(gh, fake_gh_script(required_json, full_json, pr_head, runs, review_pages, review_error,
                                    required_check_fields, rejected_check_field, check_stderr, check_status,
                                    required_check_error, full_check_error))
      FileUtils.chmod(0o755, gh)
      env = { "PATH" => "#{dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}" }
      yield env
    end
  end

  # The fake gh handles `gh repo view ...` (so --repo is optional) and
  # `gh pr checks ...`, returning the required vs full payload based on the
  # presence of the --required flag. Non-JSON ("") models "no required checks".
  def fake_gh_script(required_json, full_json, pr_head, runs, review_pages, review_error, required_check_fields,
                     rejected_check_field, check_stderr, check_status, required_check_error, full_check_error)
    run_cases = runs.map do |run_id, payload|
      run_json = JSON.generate(payload.fetch(:run))
      jobs_json = JSON.generate("total_count" => payload.fetch(:jobs).length, "jobs" => payload.fetch(:jobs))
      jobs_case =
        if payload.fetch(:jobs_error, false)
          <<~BASH
            if [[ "$*" = *"actions/runs/#{run_id}/jobs"* ]]; then
              echo 'jobs should not be fetched for this run' >&2
              exit 1
            fi
          BASH
        else
          <<~BASH
            if [[ "$*" = *"actions/runs/#{run_id}/jobs"* ]]; then
              cat <<'JSON'
            #{jobs_json}
            JSON
              exit 0
            fi
          BASH
        end
      <<~BASH
        #{jobs_case}
        if [[ "$*" = *"actions/runs/#{run_id}"* ]]; then
          cat <<'JSON'
        #{run_json}
        JSON
          exit 0
        fi
      BASH
    end.join("\n")

    review_cases = review_pages.filter_map do |cursor, payload|
      next if cursor.nil?

      <<~BASH
        if [[ "$*" = *"endCursor=#{cursor}"* ]]; then
          cat <<'JSON'
        #{JSON.generate(payload)}
        JSON
          exit 0
        fi
      BASH
    end.join("\n")
    first_page = review_pages.fetch(nil, {
                                      "data" => {
                                        "repository" => {
                                          "pullRequest" => {
                                            "reviews" => {
                                              "nodes" => [],
                                              "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                                            }
                                          }
                                        }
                                      }
                                    })
    check_fields_guard = if required_check_fields
                           <<~BASH
                             if [[ " $* " != *" --json #{required_check_fields} "* ]]; then
                               exit 2
                             fi
                           BASH
                         else
                           ""
                         end
    rejected_check_field_guard = if rejected_check_field
                                   <<~BASH
                                     if [[ "$*" = *"#{rejected_check_field}"* ]]; then
                                       exit 1
                                     fi
                                   BASH
                                 else
                                   ""
                                 end
    check_stderr_command = check_stderr ? "printf '%b' #{check_stderr.inspect} >&2" : ""
    required_check_error_command = if required_check_error
                                     <<~BASH
                                       printf '%b' #{required_check_error.inspect} >&2
                                       exit 1
                                     BASH
                                   else
                                     ""
                                   end
    full_check_error_command = if full_check_error
                                 <<~BASH
                                   printf '%b' #{full_check_error.inspect} >&2
                                   exit 1
                                 BASH
                               else
                                 ""
                               end

    <<~SH
      #!/usr/bin/env bash
      if [ "$1" = "repo" ] && [ "$2" = "view" ]; then
        printf 'owner/repo'
        exit 0
      fi
      if [ "$1" = "pr" ] && [ "$2" = "view" ]; then
        cat <<'JSON'
      {"headRefOid":#{pr_head.inspect}}
      JSON
        exit 0
      fi
      if [ "$1" = "pr" ] && [ "$2" = "checks" ]; then
      #{check_fields_guard}
      #{rejected_check_field_guard}
        #{check_stderr_command}
        for arg in "$@"; do
          if [ "$arg" = "--required" ]; then
          #{required_check_error_command}
            printf '%s' #{required_json.inspect}
            exit #{check_status}
          fi
        done
      #{full_check_error_command}
        printf '%s' #{full_json.inspect}
        exit #{check_status}
      fi
      if [ "$1" = "api" ]; then
        if [ "$2" = "graphql" ]; then
          if #{review_error}; then
            exit 1
          fi
      #{review_cases}
          cat <<'JSON'
      #{JSON.generate(first_page)}
      JSON
          exit 0
        fi
      #{run_cases}
      fi
      exit 1
    SH
  end

  def run_script(env, *)
    Open3.capture2e(env, "ruby", SCRIPT, *)
  end

  def test_check_fetch_requests_workflow_identity
    with_fake_gh(
      required_json: '[{"workflow":"CI","name":"unit","bucket":"pass"}]',
      full_json: "[]",
      required_check_fields: "name,state,bucket,link,workflow"
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      assert_equal "READY", JSON.parse(out)["verdict"]
    end
  end

  def test_required_checks_used_when_present
    with_fake_gh(
      required_json: '[{"name":"rspec","state":"SUCCESS","bucket":"pass","link":"x"}]',
      full_json: '[{"name":"rspec","bucket":"pass"},{"name":"extra","bucket":"fail"}]'
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_equal true, data["required_used"]
      assert_equal 123, data["pr"]
    end
  end

  def test_pending_current_head_review_drafts_block_ready_checks
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "3f67da47c44b7f403c72be2ed8f5bf4505666974",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [
                    { "id" => "PRR_one", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "3f67da47c44b7f403c72be2ed8f5bf4505666974" } },
                    { "id" => "PRR_two", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "3f67da47c44b7f403c72be2ed8f5bf4505666974" } }
                  ],
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(%w[PRR_one PRR_two], data.fetch("viewer_pending_review_drafts").map { |review| review["id"] })
      assert_equal "authenticated_viewer", data.fetch("viewer_review_inventory").fetch("scope")
    end
  end

  def test_pending_current_head_review_drafts_block_unknown_checks
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      pr_head: "current-head",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [
                    { "id" => "PRR_one", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "current-head" } }
                  ],
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(["PRR_one"], data.fetch("viewer_pending_review_drafts").map { |review| review["id"] })
    end
  end

  def test_submitted_dismissed_and_old_head_drafts_do_not_block_ready_checks
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "current-head",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [
                    { "id" => "PRR_submitted", "state" => "COMMENTED", "submittedAt" => "2026-07-12T00:00:00Z",
                      "commit" => { "oid" => "current-head" } },
                    { "id" => "PRR_dismissed", "state" => "DISMISSED", "submittedAt" => nil,
                      "commit" => { "oid" => "current-head" } },
                    { "id" => "PRR_old", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "old-head" } }
                  ],
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_empty data.fetch("viewer_pending_review_drafts")
      assert_equal true, data.fetch("viewer_review_inventory").fetch("complete")
    end
  end

  def test_incomplete_review_inventory_is_unknown
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [],
                  "pageInfo" => { "hasNextPage" => true, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal "authenticated_viewer", data.fetch("viewer_review_inventory").fetch("scope")
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
    end
  end

  def test_incomplete_review_inventory_does_not_overwrite_not_ready_checks
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pending"}]',
      full_json: "[]",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => {},
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
    end
  end

  def test_unavailable_review_inventory_is_unknown
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      review_error: true
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal "authenticated_viewer", data.fetch("viewer_review_inventory").fetch("scope")
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
    end
  end

  def test_malformed_review_inventory_is_unknown
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => {},
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal "authenticated_viewer", data.fetch("viewer_review_inventory").fetch("scope")
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
    end
  end

  def test_pending_current_head_draft_on_later_review_page_blocks_ready_checks
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "current-head",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [],
                  "pageInfo" => { "hasNextPage" => true, "endCursor" => "cursor-1" }
                }
              }
            }
          }
        },
        "cursor-1" => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [
                    { "id" => "PRR_later", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "current-head" } }
                  ],
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(["PRR_later"], data.fetch("viewer_pending_review_drafts").map { |review| review["id"] })
      assert_equal 2, data.fetch("viewer_review_inventory").fetch("pages")
    end
  end

  def test_partial_review_inventory_keeps_early_pending_drafts
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "current-head",
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => [
                    { "id" => "PRR_early", "state" => "PENDING", "submittedAt" => nil,
                      "commit" => { "oid" => "current-head" } }
                  ],
                  "pageInfo" => { "hasNextPage" => true, "endCursor" => "cursor-1" }
                }
              }
            }
          }
        },
        "cursor-1" => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => {},
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "31", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(["PRR_early"], data.fetch("viewer_pending_review_drafts").map { |review| review["id"] })
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
      assert_equal 1, data.fetch("viewer_review_inventory").fetch("pages")
    end
  end

  def test_falls_back_to_full_when_no_required_checks
    # Empty required payload => fall back to full list, required_used flips false.
    with_fake_gh(
      required_json: "",
      full_json: '[{"name":"lint","state":"FAILURE","bucket":"fail","link":"x"}]'
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_equal ["lint"], data["failing"]
    end
  end

  def test_totally_empty_is_unknown_via_cli
    with_fake_gh(required_json: "", full_json: "[]") do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal false, data["required_used"]
    end
  end

  def test_cancel_only_required_falls_back_to_full_list
    # A required list of only cancelled rows is not usable: it must fall back to
    # the full check list (which here surfaces a real failure) instead of
    # silently collapsing to UNKNOWN.
    with_fake_gh(
      required_json: '[{"name":"stale","state":"CANCELLED","bucket":"cancel","link":"x"}]',
      full_json: '[{"name":"lint","state":"FAILURE","bucket":"fail","link":"x"}]'
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      # required form had no usable rows, so the full list was used.
      assert_equal false, data["required_used"]
      assert_equal ["lint"], data["failing"]
    end
  end

  def test_cancel_only_required_and_empty_full_is_not_ready_via_cli
    with_fake_gh(
      required_json: '[{"name":"stale","state":"CANCELLED","bucket":"cancel","link":"x"}]',
      full_json: "[]"
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_equal ["stale"], data["pending"]
    end
  end

  def test_cancelled_required_context_blocks_unrelated_full_list_pass
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: '[{"workflow":"CI","name":"unit","bucket":"pass"}]'
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_equal ["security"], data["pending"]
    end
  end

  def test_full_list_pass_cannot_authenticate_failed_required_query
    with_fake_gh(
      required_json: "",
      full_json: '[{"workflow":"CI","name":"unit","bucket":"pass"}]',
      required_check_error: "HTTP 503 while querying required checks\n"
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal false, data["required_used"]
    end
  end

  def test_known_good_no_required_diagnostic_allows_full_list_pass
    with_fake_gh(
      required_json: "",
      full_json: '[{"workflow":"CI","name":"unit","bucket":"pass"}]',
      check_stderr: "no required checks reported on the 'feature' branch\n",
      check_status: 1
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_equal false, data["required_used"]
    end
  end

  def test_full_list_current_pass_supersedes_cancelled_required_context_with_same_identity
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: '[{"workflow":"Security","name":"security","bucket":"pass"}]'
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_empty data["pending"]
    end
  end

  def test_same_context_current_pass_supersedes_cancelled_history_via_cli
    with_fake_gh(
      required_json: '[{"workflow":"CI","name":"rspec","bucket":"pass"},{"workflow":"CI","name":"rspec","bucket":"cancel"}]',
      full_json: "[]"
    ) do |env|
      out, = run_script(env, "123", "--repo", "owner/repo")
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
    end
  end

  def test_text_mode_via_cli
    with_fake_gh(
      required_json: '[{"name":"lint","bucket":"fail"}]',
      full_json: "[]"
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--text")
      assert status.success?, out
      assert_includes out, "NOT_READY"
      assert_includes out, "failing: lint"
    end
  end

  def test_text_mode_surfaces_requested_hosted_pending
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "in_progress",
                 "conclusion" => nil, "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "queued", "conclusion" => nil,
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42", "--text")
      assert status.success?, out
      assert_includes out, "requested_hosted_pending: hosted, hosted / linux"
      assert_includes out, "requested_hosted_failing: (none)"
    end
  end

  def test_text_mode_surfaces_invalid_requested_hosted_run
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "abc123",
      runs: {}
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "not-a-run", "--text")
      assert status.success?, out
      assert_includes out, "UNKNOWN"
      assert_includes out, "requested_hosted_unknown: not-a-run: requested hosted run must be a run id"
    end
  end

  def test_repo_defaults_to_gh_repo_view
    with_fake_gh(
      required_json: '[{"name":"rspec","bucket":"pass"}]',
      full_json: "[]"
    ) do |env|
      out, status = run_script(env, "123")
      assert status.success?, out
      assert_equal "READY", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_pending_blocks_ready_required_gate
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"},{"name":"advisory","bucket":"pending"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "in_progress",
                 "conclusion" => nil, "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "queued", "conclusion" => nil,
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(["hosted", "hosted / linux"], data.fetch("requested_hosted").fetch("pending").map { |row| row["name"] })
      assert_empty data.fetch("requested_hosted").fetch("failing")
    end
  end

  def test_incomplete_review_inventory_does_not_overwrite_not_ready_requested_hosted_run
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: "[]",
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "in_progress",
                 "conclusion" => nil, "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      },
      review_pages: {
        nil => {
          "data" => {
            "repository" => {
              "pullRequest" => {
                "reviews" => {
                  "nodes" => {},
                  "pageInfo" => { "hasNextPage" => false, "endCursor" => nil }
                }
              }
            }
          }
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal false, data.fetch("viewer_review_inventory").fetch("complete")
      assert_equal(["hosted"], data.fetch("requested_hosted").fetch("pending").map { |row| row["name"] })
    end
  end

  def test_requested_hosted_run_status_blocks_ready_even_when_jobs_completed
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "in_progress",
                 "conclusion" => nil, "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "completed", "conclusion" => "success",
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      pending_names = data.fetch("requested_hosted").fetch("pending").map { |row| row["name"] }
      assert_equal ["hosted"], pending_names
      assert_empty data.fetch("requested_hosted").fetch("failing")
    end
  end

  def test_requested_hosted_failure_blocks_ready_required_gate
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "failure", "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "completed", "conclusion" => "failure",
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal(["hosted", "hosted / linux"], data.fetch("requested_hosted").fetch("failing").map { |row| row["name"] })
      assert_empty data.fetch("requested_hosted").fetch("pending")
    end
  end

  def test_requested_hosted_success_keeps_required_gate_ready_despite_unrelated_advisory_pending
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"},{"name":"unrelated advisory","bucket":"pending"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "completed", "conclusion" => "success",
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_empty data.fetch("requested_hosted").fetch("pending")
      assert_empty data.fetch("requested_hosted").fetch("failing")
      assert_empty data.fetch("requested_hosted").fetch("stale")
    end
  end

  def test_requested_hosted_success_does_not_fetch_jobs
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: [],
          jobs_error: true
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_empty data.fetch("requested_hosted").fetch("unknown")
    end
  end

  def test_requested_hosted_success_is_ready_without_required_checks_despite_unrelated_advisory_pending
    with_fake_gh(
      required_json: "",
      full_json: '[{"name":"unrelated advisory","bucket":"pending"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: [
            { "id" => 7, "name" => "hosted / linux", "status" => "completed", "conclusion" => "success",
              "html_url" => "https://example.test/jobs/7" }
          ]
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_equal false, data["required_used"]
      assert_empty data["pending"]
      assert_empty data.fetch("requested_hosted").fetch("pending")
    end
  end

  def test_requested_hosted_success_does_not_erase_cancelled_required_context
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: "[]",
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal ["security"], data["pending"]
      assert_empty data.fetch("requested_hosted").fetch("failing")
    end
  end

  def test_requested_hosted_success_accepts_same_context_full_list_supersession
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: '[{"workflow":"Security","name":"security","bucket":"pass"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "READY", data["verdict"]
      assert_empty data["pending"]
    end
  end

  def test_requested_hosted_success_does_not_accept_different_workflow_supersession
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: '[{"workflow":"CI","name":"security","bucket":"pass"}]',
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal ["security"], data["pending"]
    end
  end

  def test_requested_hosted_success_does_not_override_failed_full_supersession_query
    with_fake_gh(
      required_json: '[{"workflow":"Security","name":"security","bucket":"cancel"}]',
      full_json: '[{"workflow":"Security","name":"security","bucket":"pass"}]',
      full_check_error: "HTTP 503 while querying full checks\n",
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "NOT_READY", data["verdict"]
      assert_equal ["security"], data["pending"]
    end
  end

  def test_requested_hosted_success_is_unknown_when_old_gh_rejects_workflow_field
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      rejected_check_field: "workflow",
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_plain_invocation_is_unknown_when_old_gh_rejects_workflow_field
    with_fake_gh(required_json: "", full_json: "[]", rejected_check_field: "workflow") do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_ready_after_known_good_no_required_checks_diagnostic
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: "no required checks reported on the 'feature' branch\n",
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "READY", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_ready_after_known_good_no_checks_diagnostic_with_crlf
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: "no checks reported on the 'feature' branch\r\n",
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "READY", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_unknown_when_no_checks_diagnostic_has_trailing_error_line
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: "no required checks reported on the 'feature' branch\nHTTP 503 while querying checks\n",
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_unknown_when_no_checks_diagnostic_has_same_line_suffix
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: "no required checks reported on the 'feature' branch; HTTP 503 while querying checks\n",
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_unknown_without_exception_for_invalid_stderr_byte
    invalid_stderr = "no required checks reported on the 'feat".b + "\xFF".b + "ure' branch\n".b
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: invalid_stderr,
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_success_is_unknown_for_malformed_non_utf8_stderr_sequence
    malformed_stderr = "no required checks reported on the 'feat".b + "\xC3\x28".b + "ure' branch\n".b
    with_fake_gh(
      required_json: "",
      full_json: "[]",
      check_stderr: malformed_stderr,
      check_status: 1,
      pr_head: "abc123",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "abc123", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      assert_equal "UNKNOWN", JSON.parse(out)["verdict"]
    end
  end

  def test_requested_hosted_stale_head_is_unknown_when_base_gate_is_ready
    with_fake_gh(
      required_json: '[{"name":"unit","bucket":"pass"}]',
      full_json: '[{"name":"unit","bucket":"pass"}]',
      pr_head: "new-head",
      runs: {
        "42" => {
          run: { "id" => 42, "name" => "hosted", "head_sha" => "old-head", "status" => "completed",
                 "conclusion" => "success", "html_url" => "https://example.test/runs/42" },
          jobs: []
        }
      }
    ) do |env|
      out, status = run_script(env, "123", "--repo", "owner/repo", "--requested-hosted-run", "42")
      assert status.success?, out
      data = JSON.parse(out)
      assert_equal "UNKNOWN", data["verdict"]
      assert_equal(["42"], data.fetch("requested_hosted").fetch("stale").map { |row| row["run_id"] })
    end
  end

  # --- arg validation (no gh needed) ---------------------------------------

  def test_rejects_non_integer_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "not-a-number", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_zero_pr
    out, status = Open3.capture2e("ruby", SCRIPT, "0", "--repo", "owner/repo")
    refute status.success?
    assert_includes out, "positive integer PR number is required"
  end

  def test_rejects_bad_repo_form
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "owneronly")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_extra_path_segment
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "a/b/c")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_repo_with_empty_owner
    out, status = Open3.capture2e("ruby", SCRIPT, "12", "--repo", "/repo")
    refute status.success?
    assert_includes out, "--repo must be in OWNER/REPO form"
  end

  def test_rejects_unknown_option
    out, status = Open3.capture2e("ruby", SCRIPT, "--bogus")
    refute status.success?
    assert_includes out, "unknown option: --bogus"
  end

  def test_help_exits_zero
    out, status = Open3.capture2e("ruby", SCRIPT, "--help")
    assert status.success?, out
    assert_includes out, "Usage: pr-ci-readiness"
  end

  def test_self_check_passes
    out, status = Open3.capture2e("ruby", SCRIPT, "--self-check")
    assert status.success?, out
    assert_includes out, "self-check passed"
  end
end
