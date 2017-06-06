class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

	def create_route
		route "get '#{name}', to: '#{name}#index'"
	end

	def create_view_directory
		empty_directory("app/views/pages/components/#{name}")
	end

	def create_view
		create_file "app/views/pages/components/#{name}/#{name}.html.erb", "<%= react_component('#{name}', {prerender: false}) %>"
		create_file "app/assets/stylesheets/#{name}.scss"
	end

	def create_component_directory
		empty_directory("client/app/components/#{name}")
	end

	def create_component_index
		create_file "client/app/components/#{name}/#{name}.js",
"import React, { Component } from 'react';

class #{name} extends Component {
  render() {
    return (
			<div>#{name} Component</div>
		)
	}
}

export default #{name};"
		inject_into_file "client/app/registration.jsx", "  #{name},\n", :before => /^}/
		inject_into_file "client/app/registration.jsx", "import #{name} from './components/#{name}/#{name}';\n", :after => "import ReactOnRails from 'react-on-rails';\n"
	end
end
