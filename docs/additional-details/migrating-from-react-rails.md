## Migrate From react-rails
If you are using [react-rails](https://github.com/reactjs/react-rails) in your project, it is pretty simple to migrate to [react_on_rails](https://github.com/shakacode/react_on_rails).

- Remove the 'react-rails' gem from your Gemfile.

- Remove the generated lines for react-rails in your application.js file.

```
//= require react
//= require react_ujs
//= require components
```

- Follow our getting started guide: https://github.com/shakacode/react_on_rails#getting-started.

Note: If you have components from react-rails you want to use, then you will need to port them into react_on_rails which uses webpack instead of the asset pipeline.

