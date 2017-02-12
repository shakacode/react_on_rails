class ContainerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

	def create_route
		route "get '#{name}', to: '#{name}#index'"
	end

	def create_directory
		empty_directory("app/views/pages/containers/#{name}")
	end

	def create_view
		create_file "app/views/pages/containers/#{name}/#{name}.html.erb", "<%= react_component('#{name}', {prerender: false}) %>"
		create_file "app/assets/stylesheets/#{name}.scss"
	end

	def create_directory
		empty_directory("client/app/containers/#{name}")
	end

	def create_contianer_index
		create_file "client/app/containers/#{name}/#{name}.js",
"import React, { Component } from 'react';
import * as actions from './actions';

class #{name} extends Component {
  render() {
    return (
      <div>#{name} Container</div>
    );
  }
}

export default #{name};"
		inject_into_file "client/app/registration.jsx", "  #{name},\n", :before => /^}/
		inject_into_file "client/app/registration.jsx", "import #{name} from './containers/#{name}/#{name}';\n", :after => "import ReactOnRails from 'react-on-rails';\n"
	end

	def copy_container_files
		copy_file "container/constants.js", "client/app/containers/#{name}/constants.js"
		copy_file "container/actions.js", "client/app/containers/#{name}/actions.js"
		copy_file "container/reducer.js", "client/app/containers/#{name}/reducer.js"
  end
end
