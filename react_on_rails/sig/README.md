# RBS Type Signatures

This directory contains RBS (Ruby Signature) type definitions for the React on Rails gem.

## What is RBS?

RBS is Ruby's official type signature language. It provides type information for Ruby code, enabling:

- Better IDE support and autocomplete
- Static type checking with tools like Steep
- Improved documentation
- Early detection of type-related bugs

## Structure

The signatures are organized to mirror the `lib/` directory structure:

- `react_on_rails.rbs` - Main module and core classes
- `react_on_rails/configuration.rbs` - Configuration class types
- `react_on_rails/helper.rbs` - View helper method signatures
- `react_on_rails/server_rendering_pool.rbs` - Server rendering types
- `react_on_rails/utils.rbs` - Utility method signatures
- And more...

## Validation

To validate the RBS signatures:

```bash
bundle exec rake rbs:validate
```

Or directly:

```bash
bundle exec rbs -I sig validate
```

To list all RBS files:

```bash
bundle exec rake rbs:list
```

## Development

When adding new public methods or classes to the gem, please also add corresponding RBS signatures.

For more information about RBS:

- [RBS Documentation](https://github.com/ruby/rbs)
- [RBS Syntax Guide](https://github.com/ruby/rbs/blob/master/docs/syntax.md)
