require File.expand_path('../helper', __FILE__)

class TestDigest < TestCase
  class << self
    attr_accessor :assets_path
    attr_accessor :tar_path
    attr_accessor :recipe

    def startup
      @assets_path = File.expand_path("../assets", __FILE__)
      @tar_path = File.expand_path("../../tmp/test-digest-1.0.0.tar.gz", __FILE__)

      # remove any previous test files
      FileUtils.rm_rf("tmp")

      create_tar(@tar_path, @assets_path)
      start_webrick(File.dirname(@tar_path))
    end

    def shutdown
      stop_webrick
      # leave test files for inspection
    end
  end

  def setup
    # remove any download files
    FileUtils.rm_rf("ports/archives")

    @recipe = MiniPortile.new("test-digest", "1.0.0")
  end

  def download_with_digest(key, klass)
    @recipe.files << {
      :url => "http://localhost:#{self.class.webrick.config[:Port]}/#{ERB::Util.url_encode(File.basename(self.class.tar_path))}",
      key => klass.file(self.class.tar_path).hexdigest,
    }
    @recipe.download
  end

  def download_with_wrong_digest(key)
    @recipe.files << {
      :url => "http://localhost:#{self.class.webrick.config[:Port]}/#{ERB::Util.url_encode(File.basename(self.class.tar_path))}",
      key => "0011223344556677",
    }
    assert_raise(RuntimeError){ @recipe.download }
  end

  def test_sha256
    download_with_digest(:sha256, Digest::SHA256)
  end

  def test_wrong_sha256
    download_with_wrong_digest(:sha256)
  end

  def test_sha1
    download_with_digest(:sha1, Digest::SHA1)
  end

  def test_wrong_sha1
    download_with_wrong_digest(:sha1)
  end

  def test_md5
    download_with_digest(:md5, Digest::MD5)
  end

  def test_wrong_md5
    download_with_wrong_digest(:md5)
  end
end
