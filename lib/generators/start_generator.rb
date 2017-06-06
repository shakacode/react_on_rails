class StartGenerator < Rails::Generators::Base
	source_root File.expand_path('../templates', __FILE__)

	def delete_bundles_folder
		system("rm -rf client/app/bundles")
	end

	def create_base_files
		generate(:scaffold, "page --skip-template-engine --no-view-specs --no-jbuilder --no-stylesheets" )
		rails_command("db:migrate")
		route "root 'pages#index'"
	end

	def install_views
		create_file "app/views/pages/index.html.erb", "<%= react_component('Index', {prerender: false}) %>"
		create_file "app/assets/stylesheets/App.scss",
".App {
	text-align: center
}"
	end

	def create_registration
		copy_file "registration.jsx", "client/app/registration.jsx"
		copy_file "Index.jsx", "client/app/Index.jsx"
		copy_file "App.jsx", "client/app/App.jsx"
		copy_file "reducers/index.js", "client/app/reducers/index.js"
		copy_file "package.json", "client/package.json", force: true
		copy_file "webpack.config.js", "client/webpack.config.js", force: true
		system("gem install foreman")
		system("bundle && npm install")
	end

	def start_server
		system("foreman start -f Procfile.dev")
	end
end
