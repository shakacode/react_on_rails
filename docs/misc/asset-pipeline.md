# Asset Pipeline with React on Rails

In general, you should not be mixing the asset pipeline with Shakapacker and React on Rails.

If you're using React, then all of your CSS and images should be under either `/app/javascript` or
`/client` or wherever you want your client-side application.

If you are incrementally migrating a large application, your main concern will be how to minimize
duplication of styles and images between your old application and the new one.

Please email [justin@shakacode.com](mailto:justin@shakacode.com) if you would be interested in helping
to migrate a larger application.
