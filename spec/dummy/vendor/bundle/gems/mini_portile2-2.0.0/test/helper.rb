require 'test/unit'
require 'webrick'
require 'fileutils'
require 'zlib'
require 'archive/tar/minitar'
require 'fileutils'
require 'erb'
require 'mini_portile2'

class TestCase < Test::Unit::TestCase
  class << self
    HTTP_PORT = 23523

    attr_accessor :webrick

    def start_webrick(path)
      @webrick = WEBrick::HTTPServer.new(:Port => HTTP_PORT, :DocumentRoot => path).tap do |w|
        Thread.new do
          w.start
        end
        until w.status==:Running
          sleep 0.1
        end
      end
    end

    def stop_webrick
      if w=@webrick
        w.shutdown
        until w.status==:Stop
          sleep 0.1
        end
      end
    end

    def create_tar(tar_path, assets_path)
      FileUtils.mkdir_p(File.dirname(tar_path))
      Zlib::GzipWriter.open(tar_path) do |fdtgz|
        Dir.chdir(assets_path) do
          Archive::Tar::Minitar.pack("test mini portile-1.0.0", fdtgz)
        end
      end
    end

    def work_dir(r=recipe)
      "tmp/#{r.host}/ports/#{r.name}/#{r.version}/#{r.name}-#{r.version}"
    end
  end
end
