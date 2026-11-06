# frozen_string_literal: true

require "digest"
require "json"

# Reconcile screened prose with independently fetched, body-free GitHub metadata.
class ShakaScreenedComments
  SECTIONS = { "issue_comments" => "issue_comment", "review_summaries" => "review_summary",
               "inline_comments" => "inline_comment" }.freeze

  def initialize(packet, head)
    unless packet.is_a?(Hash) && packet["head"] == head
      raise PrMergeLedger::Error, "screened comments head does not match live PR"
    end

    @packet = packet
    @entries = {}
    @seen = []
    validate_sources!
    SECTIONS.each_key do |section|
      packet.fetch(section).each { |entry| add_entry(section, entry, withheld: false) }
    end
    add_exclusions!
  end

  def apply!(rows, section)
    rows.each do |row|
      raise PrMergeLedger::Error, "raw comment body reached screened collector" if row.key?("body")

      key = [section, row.fetch("url")]
      entry, withheld = @entries.fetch(key) { raise PrMergeLedger::Error, "live interaction is not screened" }
      unless entry.fetch("author") == actor_login(row)
        raise PrMergeLedger::Error, "screened comment actor does not match metadata: #{row.fetch('url')}"
      end

      unless withheld
        raise PrMergeLedger::Error, "screened comment body is missing" unless entry["body"].is_a?(String)

        row["body"] = entry.fetch("body")
      end
      @seen << key
    end
  end

  def verify_complete!
    return if @entries.keys.sort == @seen.sort

    raise PrMergeLedger::Error, "screened interactions do not match live metadata"
  end

  def provenance
    {
      "head" => @packet.fetch("head"),
      "packet_sha256" => Digest::SHA256.hexdigest(JSON.generate(@packet)),
      "trust_sources" => @packet.fetch("trust_sources").map { |source| source.slice("scope", "sha256") },
      "withheld_count" => @entries.values.count { |_entry, withheld| withheld },
      "withheld_interactions" => @entries.values.filter_map do |entry, withheld|
        entry.slice("kind", "url", "author") if withheld
      end
    }
  end

  private

  def validate_sources!
    sources = @packet.fetch("trust_sources")
    valid = sources.is_a?(Array) && !sources.empty? && sources.all? do |source|
      source.is_a?(Hash) && source["sha256"].to_s.match?(/\A[0-9a-f]{64}\z/)
    end
    raise PrMergeLedger::Error, "screened comments are missing trust provenance" unless valid
  end

  def add_exclusions!
    @packet.fetch("excluded_interactions").each do |entry|
      section = SECTIONS.key(entry.fetch("kind"))
      valid_flag = entry["body_withheld"] == true || entry["body_withheld"] == false
      unless section && valid_flag && entry["verification_unavailable"] == false
        raise PrMergeLedger::Error, "screened comment verification is unavailable"
      end

      add_entry(section, entry, withheld: true)
    end
  end

  def actor_login(row)
    actor = row.fetch("author")
    login = actor.fetch("login")
    actor["__typename"] == "Bot" && !login.end_with?("[bot]") ? "#{login}[bot]" : login
  end

  def add_entry(section, entry, withheld:)
    key = [section, entry.fetch("url")]
    raise PrMergeLedger::Error, "duplicate screened interaction" if @entries.key?(key)

    @entries[key] = [entry, withheld]
  end
end
