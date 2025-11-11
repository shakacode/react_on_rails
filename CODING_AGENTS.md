# 🤖 Coding Agents & AI Contributors Guide

This guide provides specific guidelines for AI coding agents (like Claude Code) contributing to React on Rails. It supplements the main [CONTRIBUTING.md](./CONTRIBUTING.md) with AI-specific workflows and patterns.

## Quick Reference Commands

### Essential Commands

```bash
# Install dependencies
bundle && yarn

# Run tests
bundle exec rspec                    # All tests (from project root)
cd spec/dummy && bundle exec rspec   # Dummy app tests only

# Linting & Formatting
bundle exec rubocop                  # Ruby linting
bundle exec rubocop [file_path]     # Lint specific file
# Note: yarn format requires local setup, format manually

# Development
cd spec/dummy && foreman start       # Start dummy app with webpack
```

### CI Compliance Checklist

- [ ] `bundle exec rubocop` passes with no offenses
- [ ] All RSpec tests pass
- [ ] No trailing whitespace
- [ ] Line length ≤120 characters
- [ ] Security violations properly scoped with disable comments
- [ ] No `package-lock.json` or other non-Yarn lock files (except `Gemfile.lock`)

## Development Patterns for AI Contributors

### 1. Task Management

Always use TodoWrite tool for multi-step tasks to:

- Track progress transparently
- Show the user what's being worked on
- Ensure no steps are forgotten
- Mark tasks complete as you finish them

```markdown
Example workflow:

1. Analyze the problem
2. Create test cases
3. Implement the fix
4. Run tests
5. Fix linting issues
6. Update documentation
```

### 2. Test-Driven Development

When fixing bugs or adding features:

1. **Create failing tests first** that reproduce the issue
2. **Implement the minimal fix** to make tests pass
3. **Add comprehensive test coverage** for edge cases
4. **Verify all existing tests still pass**

### 3. File Processing Guidelines

When working with file generation or processing:

- **Filter by extension**: Only process relevant files (e.g., `.js/.jsx/.ts/.tsx` for React components)
- **Validate assumptions**: Don't assume all files in a directory are components
- **Handle edge cases**: CSS modules, config files, etc. should be excluded appropriately

Example from CSS module fix:

```ruby
COMPONENT_EXTENSIONS = /\.(jsx?|tsx?)$/

def filter_component_files(paths)
  paths.grep(COMPONENT_EXTENSIONS)
end
```

## RuboCop Compliance Patterns

### Common Fixes

1. **Trailing Whitespace**

   ```ruby
   # Bad
   let(:value) { "test" }

   # Good
   let(:value) { "test" }
   ```

2. **Line Length (120 chars max)**

   ```ruby
   # Bad
   expect { eval(pack_content.gsub(/import.*from.*['"];/, "").gsub(/ReactOnRails\.register.*/, "")) }.not_to raise_error

   # Good
   sanitized_content = pack_content.gsub(/import.*from.*['"];/, "")
                                   .gsub(/ReactOnRails\.register.*/, "")
   expect { eval(sanitized_content) }.not_to raise_error
   ```

3. **Named Subjects (RSpec)**

   ```ruby
   # Bad
   describe "#method_name" do
     subject { instance.method_name(arg) }

     it "does something" do
       expect(subject).to eq "result"
     end
   end

   # Good
   describe "#method_name" do
     subject(:method_result) { instance.method_name(arg) }

     it "does something" do
       expect(method_result).to eq "result"
     end
   end
   ```

4. **Security/Eval Violations**

   ```ruby
   # Bad
   expect { eval(dangerous_code) }.not_to raise_error

   # Good
   # rubocop:disable Security/Eval
   sanitized_content = dangerous_code.gsub(/harmful_pattern/, "")
   expect { eval(sanitized_content) }.not_to raise_error
   # rubocop:enable Security/Eval
   ```

### RuboCop Workflow

1. Run `bundle exec rubocop [file]` to see violations
2. Fix violations manually or with auto-correct where safe
3. Re-run to verify fixes
4. Use disable comments sparingly and with good reason

## Testing Best Practices

### Test Structure

```ruby
describe "FeatureName" do
  context "when condition A" do
    let(:setup) { create_test_condition }

    before do
      # Setup code
    end

    it "does expected behavior" do
      # Arrange, Act, Assert
    end
  end
end
```

### Test Fixtures

- Create realistic test data that represents edge cases
- Use descriptive names for fixtures and variables
- Clean up after tests (handled by RSpec automatically in most cases)

### CSS Module Testing Example

```ruby
# Create test fixtures
Write.create("ComponentWithCSSModule.module.css", css_content)
Write.create("ComponentWithCSSModule.jsx", jsx_content)

# Test the behavior
it "ignores CSS module files during pack generation" do
  generated_packs = PacksGenerator.instance.generate_packs_if_stale
  expect(generated_packs).not_to include("ComponentWithCSSModule.module.js")
end
```

## Git & PR Workflow

### Branch Management

```bash
git checkout -b fix/descriptive-name
# Make changes
git add .
git commit -m "Descriptive commit message

- Bullet points for major changes
- Reference issue numbers
- Include 🤖 Generated with Claude Code signature"

git push -u origin fix/descriptive-name
```

### Commit Message Format

```
Brief description of the change

- Detailed bullet points of what changed
- Why the change was needed
- Any breaking changes or considerations

Fixes #issue_number

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### PR Creation

Use `gh pr create` with:

- Clear title referencing the issue
- Comprehensive description with summary and test plan
- Link to the issue being fixed
- Include the Claude Code signature

## Common Pitfalls & Solutions

### 1. File Path Issues

- Always use absolute paths in tools
- Check current working directory with `pwd`
- Use proper path joining methods

### 2. Test Environment

- Run tests from correct directory (often project root)
- Understand the difference between gem tests vs dummy app tests
- Clean up test artifacts appropriately

### 3. Dependency Management

- Don't assume packages are installed globally
- Use `bundle exec` for Ruby commands
- Verify setup with `bundle && yarn` when needed

### 4. RuboCop Configuration

- Different rules may apply to different directories
- Use `bundle exec rubocop` (not global rubocop)
- Check `.rubocop.yml` files for project-specific rules

## Debugging Workflow

1. **Understand the Problem**
   - Read the issue carefully
   - Reproduce the bug if possible
   - Identify root cause

2. **Create Minimal Test Case**
   - Write failing test that demonstrates issue
   - Keep it focused and minimal

3. **Implement Fix**
   - Make smallest change possible
   - Ensure fix doesn't break existing functionality
   - Follow existing code patterns

4. **Verify Solution**
   - All new tests pass
   - All existing tests still pass
   - RuboCop compliance maintained
   - Manual testing if applicable

## IDE Configuration for AI Context

When analyzing codebases, ignore these directories to avoid confusion:

- `/coverage`, `/tmp`, `/gen-examples`
- `/packages/react-on-rails/lib`, `/node_modules`
- `/spec/dummy/app/assets/webpack`
- `/spec/dummy/log`, `/spec/dummy/node_modules`, `/spec/dummy/tmp`
- `/spec/react_on_rails/dummy-for-generators`

## Communication with Human Maintainers

- Be transparent about AI-generated changes
- Explain reasoning behind implementation choices
- Ask for clarification when requirements are ambiguous
- Provide comprehensive commit messages and PR descriptions
- Include test plans and verification steps

## Resources

- [Main Contributing Guide](./CONTRIBUTING.md)
- [Pull Request Guidelines](./docs/contributor-info/pull-requests.md)
- [Generator Testing](./docs/contributor-info/generator-testing.md)
- [RuboCop Documentation](https://docs.rubocop.org/)
- [RSpec Best Practices](https://rspec.info/)

---

This guide evolves based on AI contributor experiences. Suggest improvements via issues or PRs!
