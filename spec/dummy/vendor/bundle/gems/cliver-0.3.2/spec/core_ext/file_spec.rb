# encoding: utf-8
require 'core_ext/file'

describe 'File::absolute_path?' do
  context 'posix' do
    before(:each) do
      stub_const("File::ALT_SEPARATOR", nil)
      stub_const("File::ABSOLUTE_PATH_PATTERN", File::POSIX_ABSOLUTE_PATH_PATTERN)
    end
    context 'when given an absolute path' do
      %w(
        /foo/bar
        /C/Windows/system32/
      ).each do |path|
        context "(#{path})" do
          context 'the return value' do
            subject { File::absolute_path?(path) }
            it { should be_true }
          end
        end
      end
    end
    context 'when given a relative path' do
      %w(
        C:/foo/bar
        \\foo\\bar
        C:\\foo\\bar
        foo/bar
        foo
        ./foo/bar
        ../foo/bar
        C:foo/bar
      ).each do |path|
        context "(#{path})" do
          context 'the return value' do
            subject { File::absolute_path?(path) }
            it { should be_false }
          end
        end
      end
    end
  end

  context 'windows' do
    before(:each) do
      stub_const("File::ALT_SEPARATOR", '\\')
      stub_const("File::ABSOLUTE_PATH_PATTERN", File::WINDOWS_ABSOLUTE_PATH_PATTERN)
    end
    context 'when given an absolute path' do
      %w(
        /foo/bar
        C:/foo/bar
        \\foo\\bar
        C:\\foo\\bar
        /C/Windows/system32/
      ).each do |path|
        context "(#{path})" do
          context 'the return value' do
            subject { File::absolute_path?(path) }
            it { should be_true }
          end
        end
      end
    end
    context 'when given a relative path' do
      %w(
        foo/bar
        foo
        ./foo/bar
        ../foo/bar
        C:foo/bar
      ).each do |path|
        context "(#{path})" do
          context 'the return value' do
            subject { File::absolute_path?(path) }
            it { should be_false }
          end
        end
      end
    end
  end
end
