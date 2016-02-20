# encoding: UTF-8

require 'minitest/autorun'
require 'tmpdir'

require 'archive/zip'

describe 'Archive::Zip#archive' do
  it 'adds file entries' do
    file_name = 'file'
    Dir.mktmpdir('archive_zip#archive') do |dir|
      file_path = File.join(dir, file_name)
      File.open(file_path, 'wb') { |f| f.write('data') }
      archive_file_path = File.join(dir, 'archive.zip')

      Archive::Zip.open(archive_file_path, 'w') do |a|
        a.archive(file_path)
      end

      Archive::Zip.open(archive_file_path, 'r') do |a|
        entry = a.first
        entry.wont_be_nil
        entry.zip_path.must_equal(file_name)
        entry.file?.must_equal(true)
        entry.file_data.read.must_equal('data')
      end
    end
  end

  it 'adds entries with multibyte names' do
    unless Object.const_defined?(:Encoding)
      skip("String encodings are not supported on current Ruby (#{RUBY_DESCRIPTION})")
    end

    mb_file_name = '☂file☄'
    Dir.mktmpdir('archive_zip#archive') do |dir|
      mb_file_path = File.join(dir, mb_file_name)
      File.open(mb_file_path, 'wb') { |f| f.write('data') }
      archive_file_path = File.join(dir, 'archive.zip')

      Archive::Zip.open(archive_file_path, 'w') do |a|
        a.archive(mb_file_path)
      end

      Archive::Zip.open(archive_file_path, 'r') do |a|
        entry = a.first
        entry.wont_be_nil
        entry.zip_path.must_equal(mb_file_name.dup.force_encoding('binary'))
        entry.file?.must_equal(true)
        entry.file_data.read.must_equal('data')
      end
    end
  end
end
