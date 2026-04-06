```markdown
# tldr-cli Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you how to contribute to the `tldr-cli` Ruby command-line tool project. You'll learn the repository's coding conventions, commit patterns, and step-by-step workflows for adding features or initializing new modules. Whether you're fixing bugs, adding features, or expanding the codebase, this guide will help you follow established practices.

## Coding Conventions

### File Naming
- Use **snake_case** for file names.
  - Example: `my_feature.rb`, `user_commands.rb`

### Import Style
- Use **relative imports** within the codebase.
  - Example:
    ```ruby
    require_relative '../utils/helper'
    ```

### Export Style
- Use **named exports** (explicit module/class definitions).
  - Example:
    ```ruby
    module Tldr
      class CLI
        # ...
      end
    end
    ```

### Commit Messages
- Follow **conventional commit** format.
  - Prefixes: `feat`, `chore`, `docs`
  - Example: `feat: add support for custom command aliases`

## Workflows

### Feature Development with CLI and Version Update
**Trigger:** When you want to add a new feature to the CLI.  
**Command:** `/feature-cli`

1. **Implement or update feature logic**  
   Edit or add code in `lib/tldr/cli/commands.rb` to introduce the new CLI feature.
   ```ruby
   # Example: Adding a new command
   module Tldr
     module CLI
       class Commands
         def new_feature
           puts "New feature added!"
         end
       end
     end
   end
   ```
2. **Update the version**  
   Bump the CLI version in `lib/tldr/cli/version.rb`.
   ```ruby
   module Tldr
     module CLI
       VERSION = "1.2.0"
     end
   end
   ```
3. **Document the change**  
   Add a description of the new feature to `CHANGELOG.md`.
   ```
   ## [1.2.0] - YYYY-MM-DD
   ### Added
   - New CLI feature: [describe feature]
   ```

### Initialization or Major Module Addition
**Trigger:** When you want to add a major new module or initialize the project.  
**Command:** `/new-module`

1. **Manage dependencies**  
   Add or update dependencies in `Gemfile` and `Gemfile.lock`.
   ```ruby
   gem 'some_new_gem'
   ```
2. **Create or update database migrations**  
   Add migration scripts in `db/migrate/`.
   ```ruby
   # db/migrate/20240101010101_create_examples.rb
   class CreateExamples < ActiveRecord::Migration[6.0]
     def change
       create_table :examples do |t|
         t.string :name
         t.timestamps
       end
     end
   end
   ```
3. **Add core library files**  
   Place new logic in `lib/`, often in a new subdirectory.
   ```ruby
   # lib/tldr/new_module.rb
   module Tldr
     module NewModule
       # ...
     end
   end
   ```
4. **Add supporting scripts, documentation, and/or tests**  
   - Write tests in `spec/`
   - Update `README.md` with usage or setup instructions
   - Add or update `Rakefile` as needed

## Testing Patterns

- **Test files** use the `*.test.*` pattern (e.g., `commands.test.rb`).
- The specific testing framework is **unknown**, but tests are typically placed in the `spec/` directory.
- Example test file:
  ```ruby
  # spec/commands.test.rb
  require_relative '../lib/tldr/cli/commands'

  describe Tldr::CLI::Commands do
    it 'runs new_feature successfully' do
      # test implementation
    end
  end
  ```

## Commands

| Command      | Purpose                                                        |
|--------------|----------------------------------------------------------------|
| /feature-cli | Start a new CLI feature, update version, and document changes. |
| /new-module  | Initialize a new module or major feature area.                 |
```
