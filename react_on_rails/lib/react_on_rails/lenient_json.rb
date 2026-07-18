# frozen_string_literal: true

require "json"

module ReactOnRails
  # Parses JSON produced by the JavaScript renderer, tolerating a Unicode edge case that
  # crashes Ruby's stock +JSON.parse+.
  #
  # == The problem
  #
  # JavaScript strings are UTF-16, so an astral character such as +😀+ is stored as a
  # *surrogate pair* (a high half U+D800..U+DBFF followed by a low half U+DC00..U+DFFF).
  # When application code slices a string in the middle of such a pair -- e.g. truncating
  # text for an excerpt with +slice+/+substring+ -- it leaves a *lone surrogate*: half a
  # character. +JSON.stringify+ happily serializes it as the escape +\ud83d+, but Ruby's
  # +JSON.parse+ rejects that escape with +JSON::ParserError: incomplete surrogate pair+,
  # taking down the whole server render over one bad character.
  #
  # == The fix
  #
  # Parse normally; only if Ruby raises do we repair the offending escape(s) and retry.
  # Clean payloads -- the overwhelming majority -- pay nothing: Ruby's +rescue+ costs
  # nothing until an exception is actually raised, and the repair scan/allocation happen
  # exclusively on the failure path.
  #
  # A lone surrogate is replaced with U+FFFD (+�+), the Unicode "replacement character" a
  # browser would render for broken text anyway -- passing the content through instead of
  # failing the render.
  #
  # == Known limitations
  #
  # This repairs only cases where +JSON.parse+ actually *raises*, since it works by rescuing:
  #
  # 1. A lone *low* surrogate (U+DC00..U+DFFF with no high half before it) does NOT make
  #    +JSON.parse+ raise on any json version; Ruby accepts it and returns a String whose bytes
  #    are invalid UTF-8. That case comes from the rarer prefix-drop/corrupt-data path
  #    (end-truncation, the common source, yields a lone *high* surrogate, which does raise).
  #
  # 2. On +json+ gem versions before 2.17, even a lone *high* surrogate does not raise -- the
  #    C parser silently degrades it (e.g. to "?") before Ruby sees it. There is nothing to
  #    rescue, so this is a no-op there; but there is also no crash on those versions, so
  #    nothing regresses. json >= 2.17 raises, which is where this repair engages.
  #
  # Closing either gap would require inspecting every successful parse result -- a per-request
  # cost this deliberately avoids. See issue #4710.
  module LenientJson
    # Matches a JSON +\uXXXX+ escape whose value is a lone surrogate, so it can be replaced
    # with the U+FFFD escape. A valid high+low pair is captured separately and preserved
    # (JavaScript never emits a valid pair AS escapes -- it writes the raw character -- but
    # JSON from other producers might, so the pair branch keeps us correct there too).
    #
    #   (?<!\\)((?:\\\\)*)  an even run of backslashes, so literal "\\ud83d" text is skipped
    #                       and the escape is only matched when the backslash count is odd
    #   group 2 + group 3   a valid high surrogate immediately followed by a low: keep as-is
    #   group 4             a lone surrogate (high or low, U+D800..U+DFFF): replace
    LONE_SURROGATE_ESCAPE = /
      (?<!\\)((?:\\\\)*)
      \\u(?:
        ([dD][89abAB]\h{2})\\u([dD][c-fC-F]\h{2})   # valid pair -> keep
        |([dD][89a-fA-F]\h{2})                       # lone surrogate -> U+FFFD
      )
    /x

    # Unicode replacement character (U+FFFD), the "broken character" glyph a browser would
    # render anyway. A lone surrogate escape in the JSON text is replaced with this literal
    # character; it is valid UTF-8, so the repaired JSON parses cleanly.
    REPLACEMENT_CHARACTER = "\u{FFFD}"

    module_function

    # Parses +json+, transparently repairing lone-surrogate escapes that would otherwise
    # crash Ruby's +JSON.parse+. Raises the original +JSON::ParserError+ for any failure
    # that is not caused by a repairable lone surrogate.
    def parse(json)
      JSON.parse(json)
    rescue JSON::ParserError => e
      repaired = repair_lone_surrogates(json)
      # Nothing to repair means the JSON is genuinely malformed; re-raise the true error
      # rather than parsing a second time and reporting a misleading position.
      raise e if repaired == json

      JSON.parse(repaired)
    end

    # Returns +json+ with every lone-surrogate escape replaced by U+FFFD, leaving valid
    # surrogate pairs and literal backslash text untouched.
    def repair_lone_surrogates(json)
      json.gsub(LONE_SURROGATE_ESCAPE) do
        match = Regexp.last_match
        if match[2] # a valid high+low pair: rebuild it unchanged
          "#{match[1]}\\u#{match[2]}\\u#{match[3]}"
        else # a lone surrogate: swap for the replacement character
          "#{match[1]}#{REPLACEMENT_CHARACTER}"
        end
      end
    end
  end
end
