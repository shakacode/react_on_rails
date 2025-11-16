# RBS Type Signatures

React on Rails includes [RBS](https://github.com/ruby/rbs) type signatures for improved type safety and IDE support.

## Benefits

- **Better autocomplete** in supported IDEs
- **Early detection of type errors** during development
- **Improved code documentation** through types
- **Enhanced refactoring safety** with type-aware tools

## IDE Support

RBS signatures work with:

- [Steep](https://github.com/soutaro/steep) - Static type checker for Ruby
- [Solargraph](https://solargraph.org/) - Ruby language server with RBS support
- RubyMine - Built-in RBS support
- VS Code - Via Ruby LSP extensions

## Usage

### Validation

To validate type signatures:

```bash
bundle exec rake rbs:validate
```

Or directly using the RBS CLI:

```bash
bundle exec rbs -I sig validate
```

### Listing Type Files

To see all available RBS type signature files:

```bash
bundle exec rake rbs:list
```

## Location

Type signatures are located in the `sig/` directory, organized to mirror the `lib/` directory structure:

```
sig/
├── react_on_rails.rbs              # Main module and core classes
├── react_on_rails/
│   ├── configuration.rbs           # Configuration class types
│   ├── helper.rbs                  # View helper method signatures
│   ├── server_rendering_pool.rbs   # Server rendering types
│   ├── utils.rbs                   # Utility method signatures
│   └── ...                         # And more
```

For more details, see [sig/README.md](../../sig/README.md).

## Contributing

When adding new public methods or classes to the gem, please also add corresponding RBS signatures. This helps maintain type safety and improves the development experience for all users.

### Adding New Signatures

1. Create or update the appropriate `.rbs` file in the `sig/` directory
2. Follow the existing structure and naming conventions
3. Run `bundle exec rake rbs:validate` to verify your changes
4. Include the RBS updates in your pull request

## Compatibility

- Ruby >= 3.0 (RBS is included in Ruby 3.0+)
- RBS gem >= 2.0

## Resources

- [RBS Documentation](https://github.com/ruby/rbs)
- [RBS Syntax Guide](https://github.com/ruby/rbs/blob/master/docs/syntax.md)
- [Steep Type Checker](https://github.com/soutaro/steep)
- [Solargraph Language Server](https://solargraph.org/)
