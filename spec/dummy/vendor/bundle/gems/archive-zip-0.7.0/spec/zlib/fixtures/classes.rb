# encoding: UTF-8

class ZlibSpecs
  def self.compressed_data
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_nocomp
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_minwin
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minwin.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_minmem
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minmem.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_huffman
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_huffman.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_gzip
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_gzip.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_raw
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_raw.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt'), 'rb') do |f|
      f.read
    end
  end
end
