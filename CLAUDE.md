# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dual-purpose Ruby project:

1. **tldr-cli**: A command-line client for tldr-pages (simplified man pages)
2. **gem_patterns**: An LLM-powered library for extracting Ruby gem usage patterns

## Common Development Commands

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/file_spec.rb

# Run tests with focus
bundle exec rspec --tag focus
```

### Building and Installation
```bash
# Build the gem
rake build

# Install locally
rake install

# Run tldr-cli
bin/tldr [command]
# Example: bin/tldr tar
```

### Gem Patterns Commands
```bash
# Initialize the patterns database
rake gem_patterns:init

# Generate patterns (with vector indexing)
VECTOR=1 rake gem_patterns:generate

# Search patterns
rake gem_patterns:search[query]

# Show pattern count
rake gem_patterns:count

# Reset database
rake gem_patterns:reset
```

## Architecture

### TLDR-CLI Structure
```
lib/tldr/
├── cli.rb              # Main CLI module
├── cli/
│   ├── commands.rb     # Command handling
│   └── version.rb      # Version constant
```
- Uses `tty-option` for CLI parsing
- Uses `tty-markdown` for rendering
- Uses `faraday` for HTTP requests

### Gem Patterns Structure
```
lib/gem_patterns/
├── config.rb           # Configuration and paths
├── fetch.rb            # RubyGems API interaction
├── llm.rb              # RubyLLM wrapper
├── embedder.rb         # Vector embeddings (informers)
├── store.rb            # Database operations (pgvector)
├── search.rb           # Vector similarity search
├── schema.rb           # Database schema (DDL)
├── build.rb            # Pattern generation
├── writer.rb           # JSON output
├── runner.rb           # Main orchestration
├── cli.rb              # Command-line interface
├── pattern_schema.rb   # RubyLLM schema definitions
├── content_hasher.rb   # Content deduplication
└── scenario_writer.rb  # Scenario generation
```

## Development Guidelines

### For Gem Patterns Development

#### Technical Constraints
- Keep modules under 30 lines each
- Use RubyLLM (NOT llm.rb) for LLM interactions
- Use pgvector for vector storage with HNSW index

#### Required Libraries and APIs
- **RubyLLM**: `RubyLLM.chat(model:).with_schema(SchemaClass).ask(prompt).content`
- **RubyLLM Schema**: `class Foo < RubyLLM::Schema` with `string`, `array`, `object`
- **pgvector**: `Sequel` with `pgvector` extension, `vector(384)` column type
- **informers**: `Informers.pipeline("embedding", model_name)` returns embedder

#### Architecture Patterns
- **Single Responsibility**: Each module has one clear purpose
- **Separation of Concerns**: Runner (orchestration) separate from CLI (I/O)
- **Schema Validation**: Use RubyLLM::Schema instead of manual JSON parsing

### Common Mistakes to Avoid

#### Library Confusion
- **Wrong LLM library**: Don't confuse `llm.rb` with `RubyLLM`
  - `llm.rb` uses `LLM::Bot`, `LLM.openai(key:)`
  - `RubyLLM` uses `RubyLLM.chat`, `RubyLLM::Schema`

#### Design Anti-Patterns  
- Avoid over-engineering before validating requirements
- Don't create complex tier systems when simple config works
- Don't use manual JSON parsing when RubyLLM has schema support

## Testing Strategy

### Current Test Structure
```
spec/
├── gem_patterns/       # Gem patterns tests
├── tldr/              # TLDR CLI tests
└── spec_helper.rb     # RSpec configuration
```

### Testing Guidelines
- Tests are configured for random order execution
- Use `focus` tag for targeted testing
- RSpec configured with monkey patching disabled
- Example persistence enabled in `spec/examples.txt`
