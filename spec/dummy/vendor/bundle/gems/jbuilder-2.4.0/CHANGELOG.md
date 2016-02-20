# Changelog

2.3.2
-----

* [Remove Mime Types deprecation message](https://github.com/rails/jbuilder/commit/5ba4e4ac654cc8388619538f576fe234659b84ec)

2.3.1
-----

* [Explicitly require ostruct to prevent NameError](https://github.com/rails/jbuilder/pull/281)

2.3.0
-----

* [Add new in-place partial invocation support](https://github.com/rails/jbuilder/commit/1feda7ee605c136e59fb4de970f4674de518e6de)
* [Add implicit partial rendering for AM::Models](https://github.com/rails/jbuilder/commit/4d5bf7d0ea92765adb7be36834e84f9855a061df)
* [Generate API controller if Rails API option is enabled](https://github.com/rails/jbuilder/commit/db68f6bd327cf42b47ef22d455fb5721a8c2cf5f)
* [JBuilder's templates have less priority than app templates](https://github.com/rails/jbuilder/commit/7c1a5f25603ec1f4e51fba3dbba9db23726a5d69)
* [Add AC::Helpers module to jbuilder for api only apps](https://github.com/rails/jbuilder/commit/7cf1d1eb7d125caf38309b5427952030011c1aa0)

2.2.16
------

* [Fix NoMethodError around `api_only` in railtie](https://github.com/rails/jbuilder/commit/b08d1da10b14720b46d383b2917e336060fd9ffa)

2.2.14
------

* [Make Jbuilder compatible with Rails API](https://github.com/rails/jbuilder/commit/29c0014a9c954c990075d42c45c66075260e924b)

2.2.13
------

* Several peformance optimizations: [#260](https://github.com/rails/jbuilder/pull/260) & [#261](https://github.com/rails/jbuilder/pull/261)

2.2.12
------

* [Replace explici block calls with yield for performance](https://github.com/rails/jbuilder/commit/3184f941276ad03a071cf977133d1a32302afa47)

2.2.11
------

* Generate the templates for Rails 5+ [#258](https://github.com/rails/jbuilder/pull/258) [@amatsuda](https://github.com/amatsuda)

2.2.10
------

* Add Jbuilder::Blank#empty? to tell if attributes are empty [#257](https://github.com/rails/jbuilder/pull/257) [@a2ikm](https://github.com/a2ikm)

2.2.9
-----

* Support `partial!` call with `locals` option in `JbuilderTemplate` [#251](https://github.com/rails/jbuilder/pull/251)

2.2.8
-----
* [Raise ArrayError when trying to add key to an array](https://github.com/rails/jbuilder/commit/869e4be1ad165ce986d8fca78311bdd3ed166087)

2.2.7
-----
* [Make Blank object serializable with Marshal](https://github.com/rails/jbuilder/commit/7083f28d8b665aa60d0d1b1927ae88bb5c6290ba)

2.2.6
-----
* [Make sure dependency tracker loads after template handler](https://github.com/rails/jbuilder/commit/3ba404b1207b557e14771c90b8832bc01ae67a42)

2.2.5
-----
* [Refactor merge block behavior to raise error for unexpected values](https://github.com/rails/jbuilder/commit/4503162fb26f53f613fc83ac081fd244748b6fe9)

2.2.4
-----
* [Typecast locals hash key during collection render](https://github.com/rails/jbuilder/commit/a6b0c8651a08e01cb53eee38e211c65423f275f7)

2.2.3
-----
* [Move template handler registration into railtie](https://github.com/rails/jbuilder/commit/c8acc5cea6da2a79b7b345adc301cb5ff2517647)
* [Do not capture the block where it is possible](https://github.com/rails/jbuilder/commit/973b382c3924cb59fc0e4e25266b18e74d41d646)

2.2.2
-----
* [Fix `Jbuilder#merge!` inside block](https://github.com/rails/jbuilder/commit/a7b328552eb0d36315f75bff813bea7eecf8c1d7)

2.2.1
-----
* [Fix empty block handling](https://github.com/rails/jbuilder/commit/972a11141403269e9b17b45b0c95f8a9788245ee)

2.2.0
-----
* [Allow to skip `array!` iterations by calling `next`](https://github.com/rails/jbuilder/commit/81a63308fb9d5002519dd871f829ccc58067251a)

2.1.2
-----
* [Cast array-like objects to array before merging](https://github.com/rails/jbuilder/commit/7b8c8a1cb09b7f3dd26e5643ebbd6b2ec67185db)

2.1.1
-----
* [Remove unused file](https://github.com/rails/jbuilder/commit/e49e1047976fac93b8242ab212c7b1a463b70809)

2.1.0
-----
* [Blocks and their extract! shortcuts are additive by default](https://github.com/rails/jbuilder/commit/a49390736c5f6e2d7a31111df6531bc28dba9fb1)

2.0.8
-----
* [Eliminate circular dependencies](https://github.com/rails/jbuilder/commit/0879484dc74e7be93b695f66e3708ba48cdb1be3)
* [Support cache key generation for complex objects](https://github.com/rails/jbuilder/commit/ca9622cca30c1112dd4408fcb2e658849abe1dd5)
* [Remove JbuilderProxy class](https://github.com/rails/jbuilder/commit/5877482fc7da3224e42d4f72a1386f7a3a08173b)
* [Move KeyFormatter into a separate file](https://github.com/rails/jbuilder/commit/13fee8464ff53ce853030114283c03c135c052b6)
* [Move NullError into a separate file](https://github.com/rails/jbuilder/commit/13fee8464ff53ce853030114283c03c135c052b6)

2.0.7
-----
* [Add destroy notice to scaffold generator](https://github.com/rails/jbuilder/commit/8448e86f8cdfa0f517bd59576947875775a1d43c)

2.0.6
-----
* [Use render short form in controller generator](https://github.com/rails/jbuilder/commit/acf37320a7cea7fcc70c791bc94bd5f46b8349ff)

2.0.5
-----
* [Fix edgecase when json is defined as a method](https://github.com/rails/jbuilder/commit/ca711a0c0a5760e26258ce2d93c14bef8fff0ead)

2.0.4
-----
* [Add cache_if! to conditionally cache JSON fragments](https://github.com/rails/jbuilder/commit/14a5afd8a2c939a6fd710d355a194c114db96eb2)

2.0.3
-----
* [Pass options when calling cache_fragment_name](https://github.com/rails/jbuilder/commit/07c2cc7486fe9ef423d7bc821b83f6d485f330e0)

2.0.2
-----
* [Fix Dependency Tracking fail to detect single-quoted partial correctly](https://github.com/rails/jbuilder/commit/448679a6d3098eb34d137f782a05f1767711991a)
* [Prevent Dependency Tracker constants leaking into global namespace](https://github.com/rails/jbuilder/commit/3544b288b63f504f46fa8aafd1d17ee198d77536)

2.0.1
-----
* [Dependency tracking support for Rails 3 with cache_digest gem](https://github.com/rails/jbuilder/commit/6b471d7a38118e8f7645abec21955ef793401daf)

2.0.0
-----
* [Respond to PUT/PATCH API request with :ok](https://github.com/rails/jbuilder/commit/9dbce9c12181e89f8f472ac23c764ffe8438040a)
* [Remove Ruby 1.8 support](https://github.com/rails/jbuilder/commit/d53fff42d91f33d662eafc2561c4236687ecf6c9)
* [Remove deprecated two argument block call](https://github.com/rails/jbuilder/commit/07a35ee7e79ae4b06dba9dbff5c4e07c1e627218)
* [Make Jbuilder object initialize with single hash](https://github.com/rails/jbuilder/commit/38bf551db0189327aaa90b9be010c0d1b792c007)
* [Track template dependencies](https://github.com/rails/jbuilder/commit/8e73cea39f60da1384afd687cc8e5e399630d8cc)
* [Expose merge! method](https://github.com/rails/jbuilder/commit/0e2eb47f6f3c01add06a1a59b37cdda8baf24f29)

1.5.3
-----
* [Generators add `:id` column by default](https://github.com/rails/jbuilder/commit/0b52b86773e48ac2ce35d4155c7b70ad8b3e8937)

1.5.2
-----
* [Nil-collection should be treated as empty array](https://github.com/rails/jbuilder/commit/2f700bb00ab663c6b7fcb28d2967aeb989bd43c7)

1.5.1
-----
* [Expose template lookup options](https://github.com/rails/jbuilder/commit/404c18dee1af96ac6d8052a04062629ef1db2945)

1.5.0
-----
* [Do not perform any caching when `controller.perform_caching` is false](https://github.com/rails/jbuilder/commit/94633facde1ac43580f8cd5e13ae9cc83e1da8f4)
* [Add partial collection rendering](https://github.com/rails/jbuilder/commit/e8c10fc885e41b18178aaf4dcbc176961c928d76)
* [Deprecate extract! calling private methods](https://github.com/rails/jbuilder/commit/b9e19536c2105d7f2e813006bbcb8ca5730d28a3)
* [Add array of partials rendering](https://github.com/rails/jbuilder/commit/7d7311071720548047f98f14ad013c560b8d9c3a)

1.4.2
-----
* [Require MIME dependency explicitly](https://github.com/rails/jbuilder/commit/b1ed5ac4f08b056f8839b4b19b43562e81e02a59)

1.4.1
-----
* [Removed deprecated positioned arguments initializer support](https://github.com/rails/jbuilder/commit/6e03e0452073eeda77e6dfe66aa31e5ec67a3531)
* [Deprecate two-arguments block calling](https://github.com/rails/jbuilder/commit/2b10bb058bb12bc782cbcc16f6ec67b489e5ed43)

1.4.0
-----
* [Add quick collection attribute extraction](https://github.com/rails/jbuilder/commit/c2b966cf653ea4264fbb008b8cc6ce5359ebe40a)
* [Block has priority over attributes extraction](https://github.com/rails/jbuilder/commit/77c24766362c02769d81dac000b1879a9e4d4a00)
* [Meaningfull error messages when adding properties to null](https://github.com/rails/jbuilder/commit/e26764602e34b3772e57e730763d512e59489e3b)
* [Do not enforce template format, enforce handlers instead](https://github.com/rails/jbuilder/commit/72576755224b15da45e50cbea877679800ab1398)

1.3.0
-----
* [Add nil! method for nil JSON](https://github.com/rails/jbuilder/commit/822a906f68664f61a1209336bb681077692c8475)

1.2.1
-----
* [Added explicit dependency for MultiJson](https://github.com/rails/jbuilder/commit/4d58eacb6cd613679fb243484ff73a79bbbff2d2)

1.2.0
-----
* Multiple documentation improvements and internal refactoring
* [Fixes fragment caching to work with latest digests](https://github.com/rails/jbuilder/commit/da937d6b8732124074c612abb7ff38868d1d96c0)

1.0.2
-----
* [Support non-Enumerable collections](https://github.com/rails/jbuilder/commit/4c20c59bf8131a1e419bb4ebf84f2b6bdcb6b0cf)
* [Ensure that the default URL is in json format](https://github.com/rails/jbuilder/commit/0b46782fb7b8c34a3c96afa801fe27a5a97118a4)

1.0.0
-----
* Adopt Semantic Versioning
* Add rails generators
