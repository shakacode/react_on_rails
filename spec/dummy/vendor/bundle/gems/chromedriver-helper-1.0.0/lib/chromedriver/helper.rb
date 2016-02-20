require "chromedriver/helper/version"
require "chromedriver/helper/google_code_parser"
require 'fileutils'
require 'rbconfig'
require 'open-uri'
require 'archive/zip'

module Chromedriver
  class Helper

    def run *args
      download
      exec binary_path, *args
    end

    def download hit_network=false
      return if File.exists?(binary_path) && ! hit_network
      url = download_url
      filename = File.basename url
      Dir.chdir platform_install_dir do
        FileUtils.rm_f filename
        File.open(filename, "wb") do |saved_file|
          URI.parse(url).open("rb") do |read_file|
            saved_file.write(read_file.read)
          end
        end
        raise "Could not download #{url}" unless File.exists? filename
        Archive::Zip.extract(filename, '.', :overwrite => :all)
      end
      raise "Could not unzip #{filename} to get #{binary_path}" unless File.exists? binary_path
      FileUtils.chmod "ugo+rx", binary_path
    end

    def update
      download true
    end

    def download_url
      GoogleCodeParser.new(platform).newest_download
    end

    def binary_path
      if platform == "win"
        File.join platform_install_dir, "chromedriver.exe"
      else
        File.join platform_install_dir, "chromedriver"
      end
    end

    def platform_install_dir
      dir = File.join install_dir, platform
      FileUtils.mkdir_p dir
      dir
    end

    def install_dir
      dir = File.expand_path File.join(ENV['HOME'], ".chromedriver-helper")
      FileUtils.mkdir_p dir
      dir
    end

    def platform
      cfg = RbConfig::CONFIG
      case cfg['host_os']
      when /linux/ then
        cfg['host_cpu'] =~ /x86_64|amd64/ ? "linux64" : "linux32"
      when /darwin/ then "mac"
      else "win"
      end
    end

  end
end
