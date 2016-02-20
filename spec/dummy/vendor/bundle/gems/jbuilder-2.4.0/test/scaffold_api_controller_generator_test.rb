require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/scaffold_controller_generator'

if Rails::VERSION::MAJOR > 4

  class ScaffoldApiControllerGeneratorTest < Rails::Generators::TestCase
    tests Rails::Generators::ScaffoldControllerGenerator
    arguments %w(Post title body:text --api)
    destination File.expand_path('../tmp', __FILE__)
    setup :prepare_destination

    test 'controller content' do
      run_generator

      assert_file 'app/controllers/posts_controller.rb' do |content|
        assert_instance_method :index, content do |m|
          assert_match /@posts = Post\.all/, m
        end

        assert_instance_method :show, content do |m|
          assert m.blank?
        end

        assert_instance_method :create, content do |m|
          assert_match /@post = Post\.new\(post_params\)/, m
          assert_match /@post\.save/, m
          assert_match /render :show, status: :created, location: @post/, m
          assert_match /render json: @post\.errors, status: :unprocessable_entity/, m
        end

        assert_instance_method :update, content do |m|
          assert_match /render :show, status: :ok, location: @post/, m
          assert_match /render json: @post.errors, status: :unprocessable_entity/, m
        end

        assert_instance_method :destroy, content do |m|
          assert_match /@post\.destroy/, m
        end

        assert_match(/def post_params/, content)
        assert_match(/params\.require\(:post\)\.permit\(:title, :body\)/, content)
      end
    end
  end
end
