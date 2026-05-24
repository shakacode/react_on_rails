# frozen_string_literal: true

require "fileutils"
require "rubygems/package"
require "stringio"
require "zlib"

require "react_on_rails_pro/error"

module ReactOnRailsPro
  module RollingDeploy
    # Pure-Ruby tar.gz compose/extract used by the built-in HTTP rolling-deploy
    # adapter. Stdlib only (Gem::Package::TarWriter / TarReader + Zlib) so the
    # gem stays free of native or third-party tarball dependencies.
    #
    # Wire format (one tarball per bundle hash):
    #
    #   ./bundle.js
    #   ./loadable-stats.json          (optional)
    #   ./react-client-manifest.json   (when RSC enabled)
    #   ./react-server-client-manifest.json (when RSC enabled)
    #
    # All entries are flat — the adapter renames `bundle.js` to `<hash>.js`
    # during staging. The compose side only writes regular files keyed by their
    # basename; the extract side rejects anything that isn't a basename so a
    # malicious server can't write outside `dest_dir`.
    module Tarball
      module_function

      # Default uncompressed size cap. Bundles are mostly text and gzip well, but
      # a malicious or misconfigured server could still send a multi-GB payload;
      # cap the uncompressed total at 200 MB unless the caller overrides. Used
      # by `extract` as a guard against zip-bomb-style payloads.
      DEFAULT_MAX_SIZE = 200 * 1024 * 1024

      # Per-entry read chunk during extract. Small enough that an inner large
      # file doesn't blow heap before the running total trips the size cap.
      EXTRACT_CHUNK_SIZE = 64 * 1024

      # Path-safety regex for tar entries. We require entries to be flat
      # basenames (no slashes, no `..`, no NUL bytes, no leading dot) so an
      # attacker can never write outside the target directory or hide files
      # from `ls`. The `./` prefix permitted by tar is normalised away before
      # this match runs.
      ENTRY_NAME_PATTERN = /\A(?!\.)[A-Za-z0-9_][A-Za-z0-9_.\-]*\z/

      # Compose a gzipped tarball from the given entries and yield the
      # resulting Tempfile. The temp file is removed when the block returns.
      #
      # `entries` is a Hash mapping the archive entry name (a flat basename,
      # e.g. `"bundle.js"`) to the source file path on disk. Hash form lets
      # callers rename the file in the archive — on the server side, the
      # server bundle lives at `<hash>.js` on disk but ships as `bundle.js`
      # in the tarball so the client adapter can stage it without needing
      # to know the source filename.
      def compose_to_tempfile(entries)
        require "tempfile"

        Tempfile.create(["rolling-deploy-tarball-", ".tar.gz"]) do |tempfile|
          tempfile.binmode
          compose_to_io(entries, tempfile)
          tempfile.flush
          tempfile.rewind
          yield tempfile
        end
      end

      # Compose a gzipped tarball into the given IO. The IO must accept
      # binary writes. See `compose_to_tempfile` for the `entries` shape.
      def compose_to_io(entries, io)
        validate_compose_entries!(entries)

        Zlib::GzipWriter.wrap(io) do |gz|
          Gem::Package::TarWriter.new(gz) do |tar|
            entries.each do |name, path|
              add_file_to_tar(tar, name, path)
            end
          end
        end
        io
      end

      # Extract a gzipped tarball from `source` (an IO-like or a String) into
      # `dest_dir`. Enforces:
      #   * Each entry name must be a safe basename (ENTRY_NAME_PATTERN).
      #   * Each entry must be a regular file (no dirs, symlinks, hardlinks).
      #   * Cumulative uncompressed bytes must not exceed `max_size`.
      #
      # Returns the list of basenames extracted, in the order seen in the
      # archive. Raises ReactOnRailsPro::Error on any safety or size violation;
      # callers are expected to rm_rf the partial directory and skip the hash.
      def extract(source, dest_dir, max_size: DEFAULT_MAX_SIZE)
        FileUtils.mkdir_p(dest_dir)
        io = source.is_a?(String) ? StringIO.new(source) : source
        extracted = []
        total_size = 0

        Zlib::GzipReader.wrap(io) do |gz|
          Gem::Package::TarReader.new(gz) do |tar|
            tar.each do |entry|
              name = safe_entry_name!(entry)
              raise_unless_regular_file!(entry, name)
              total_size = write_entry!(entry, dest_dir, name, total_size, max_size)
              extracted << name
            end
          end
        end
        extracted
      rescue Zlib::GzipFile::Error, Zlib::DataError => e
        raise ReactOnRailsPro::Error,
              "Rolling-deploy tarball is not a valid gzip stream: #{e.class}: #{e.message}"
      end

      def validate_compose_entries!(entries)
        entries.each do |name, path|
          unless ENTRY_NAME_PATTERN.match?(name.to_s)
            raise ReactOnRailsPro::Error,
                  "Tarball entry name #{name.inspect} is not a safe basename. " \
                  "Allowed: flat alphanumeric basenames (no slashes, no leading dot)."
          end

          raise ReactOnRailsPro::Error, "Tarball source path for #{name.inspect} is blank" if path.to_s.empty?

          unless File.file?(path)
            raise ReactOnRailsPro::Error,
                  "Tarball source path #{path.inspect} (entry #{name.inspect}) does not exist or is not a regular file"
          end
        end
      end
      private_class_method :validate_compose_entries!

      def add_file_to_tar(tar, name, path)
        stat = File.stat(path)
        # Force the mode to 0644 so the client gets a flat archive regardless
        # of what permissions / parent directories the server-side file
        # happens to have. Bundles are public-build artifacts; preserving
        # server-side ACLs is not useful and can leak operator-side
        # permission quirks into the wire format.
        tar.add_file_simple(name.to_s, 0o644, stat.size) do |io|
          File.open(path, "rb") do |source|
            IO.copy_stream(source, io)
          end
        end
      end
      private_class_method :add_file_to_tar

      def safe_entry_name!(entry)
        # `TarReader` exposes the entry name verbatim; tar archives commonly
        # prefix entries with `./`. Strip that prefix before the pattern check
        # so a legitimate `./bundle.js` doesn't get rejected, but anything more
        # exotic (subdir, leading-dot hidden name, traversal) still fails.
        raw = entry.full_name.to_s
        name = raw.delete_prefix("./")
        unless ENTRY_NAME_PATTERN.match?(name)
          raise ReactOnRailsPro::Error,
                "Rolling-deploy tarball entry name #{raw.inspect} is not a safe basename. " \
                "Allowed: flat alphanumeric basenames (no slashes, no leading dot, no `..`)."
        end
        name
      end
      private_class_method :safe_entry_name!

      def raise_unless_regular_file!(entry, name)
        return if entry.file?

        kind = if entry.directory? then "directory"
               elsif entry.symlink? then "symlink"
               else
                 "non-regular file"
               end
        raise ReactOnRailsPro::Error,
              "Rolling-deploy tarball entry #{name.inspect} is a #{kind}; " \
              "only regular files are allowed."
      end
      private_class_method :raise_unless_regular_file!

      def write_entry!(entry, dest_dir, name, total_size, max_size)
        dest = File.join(dest_dir, name)
        running = total_size
        File.open(dest, "wb") do |out|
          while (chunk = entry.read(EXTRACT_CHUNK_SIZE))
            running += chunk.bytesize
            if running > max_size
              raise ReactOnRailsPro::Error,
                    "Rolling-deploy tarball exceeds max uncompressed size of #{max_size} bytes " \
                    "(entry #{name.inspect} pushed total to #{running})."
            end
            out.write(chunk)
          end
        end
        running
      end
      private_class_method :write_entry!
    end
  end
end
