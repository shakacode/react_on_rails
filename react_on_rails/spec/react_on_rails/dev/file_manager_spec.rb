# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../spec_helper"
require "react_on_rails/dev/file_manager"

RSpec.describe ReactOnRails::Dev::FileManager do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  def write_server_pid(contents)
    FileUtils.mkdir_p("tmp/pids")
    File.write("tmp/pids/server.pid", contents)
  end

  describe ".cleanup_stale_files" do
    it "removes a copied socket file that is no longer active" do
      FileUtils.mkdir_p("tmp/sockets")
      File.write("tmp/sockets/overmind-4100.sock", "copied socket")

      expect(described_class.cleanup_stale_files).to be true
      expect(File).not_to exist("tmp/sockets/overmind-4100.sock")
    end

    it "keeps an active socket for the current app directory" do
      FileUtils.mkdir_p("tmp/sockets")
      server = UNIXServer.new("tmp/sockets/overmind.sock")

      expect(described_class.cleanup_stale_files).to be false
      expect(File.socket?("tmp/sockets/overmind.sock")).to be true
    ensure
      server&.close
    end

    it "removes an overmind socket file whose path is too long for a UNIX socket address" do
      FileUtils.mkdir_p("tmp/sockets")
      socket_file = "tmp/sockets/overmind-#{'a' * 100}.sock"
      File.write(socket_file, "copied socket")

      expect(described_class.cleanup_stale_files).to be true
      expect(File).not_to exist(socket_file)
    end

    it "removes an overmind socket file when socket allocation fails" do
      FileUtils.mkdir_p("tmp/sockets")
      File.write("tmp/sockets/overmind.sock", "copied socket")
      allow(Socket).to receive(:new).and_raise(Errno::EMFILE)

      expect(described_class.cleanup_stale_files).to be true
      expect(File).not_to exist("tmp/sockets/overmind.sock")
    end

    it "leaves non-overmind sockets in tmp/sockets/ alone even when inactive" do
      FileUtils.mkdir_p("tmp/sockets")
      File.write("tmp/sockets/puma.sock", "stale puma socket")
      File.write("tmp/sockets/cable.sock", "stale cable socket")

      described_class.cleanup_stale_files

      expect(File).to exist("tmp/sockets/puma.sock")
      expect(File).to exist("tmp/sockets/cable.sock")
    end

    it "removes a server pid file copied from another app directory" do
      write_server_pid("12345")
      allow(described_class).to receive(:process_running?).with(12_345).and_return(true)
      allow(described_class).to receive(:working_directory_for_pid).with(12_345).and_return("/tmp/other-app")

      expect(described_class.cleanup_stale_files).to be true
      expect(File).not_to exist("tmp/pids/server.pid")
    end

    it "keeps a server pid file when the running process belongs to this app directory" do
      write_server_pid("12345")
      allow(described_class).to receive(:process_running?).with(12_345).and_return(true)
      allow(described_class).to receive(:working_directory_for_pid).with(12_345).and_return(Dir.pwd)

      expect(described_class.cleanup_stale_files).to be false
      expect(File.read("tmp/pids/server.pid")).to eq("12345")
    end
  end
end
