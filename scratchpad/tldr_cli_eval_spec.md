# TLDR-CLI Evaluation Specification

Generated: 2026-04-03T14:30:00Z
Artifact type: ruby_code
Convention target: StandardRB (standard gem detected in Gemfile)
Mode: sift_report
Project: tldr-cli (33 files, ~1,030 LOC)

## Context

This specification defines the evaluation rubric for assessing the tldr-cli Ruby project based on the SIFT report findings (Overall Health: 6.5/10). The project is a CLI tool for managing tldr/cheat page embeddings and search, not a distributed system. Calibration notes reflect this scope.

## Rubric Dimensions

```yaml
rubric_dimensions:
  - name: "Schema & Migration Correctness"
    description: "Does the database schema accurately reflect the intended data model? Are all migrations executing at runtime? Are constraints consistent with upsert logic and data identity requirements?"
    scale: "1-5"
    weight: 0.18
    instruction: "Verify Schema.ensure executes all migrations (001 AND 002). Check that raw_content_hash and gem_name constraints don't conflict. Validate that migration 002 columns (source, platform, raw_content_hash) exist at runtime. Cite schema.rb and migration files."
    score_definitions:
      1: "Migrations incomplete; schema mismatch with code expectations; constraint conflicts causing runtime errors"
      2: "Migration 002 not executing; raw_content_hash conflicts with gem_name unique constraint (CURRENT STATE)"
      3: "All migrations execute; constraints functional but dual-identity design creates ambiguity"
      4: "Complete migration chain; clean constraint design; evidence of migration testing"
      5: "Full migration coverage with idempotent design; constraint design supports all use cases"

  - name: "Parser Correctness"
    description: "Do the tldr and cheat parsers extract accurate command names, descriptions, and examples? Are regex patterns robust against real-world page variations? Does content preservation work correctly for code blocks with --- delimiters?"
    scale: "1-5"
    weight: 0.16
    instruction: "Test tldr parser command_name extraction against real pages. Verify example regex handles variations. Check cheat parser frontmatter removal doesn't corrupt code blocks. Test with edge cases from actual tldr/cheat repositories."
    score_definitions:
      1: "Command names wrong; examples fail to parse; frontmatter removal corrupts content"
      2: "command_name returns description text; example regex too strict; frontmatter can corrupt code blocks (CURRENT STATE)"
      3: "Core parsing works for standard pages; edge cases fail gracefully"
      4: "Robust parsing across page variations; edge cases handled; evidence of test coverage"
      5: "Production-grade parsing with comprehensive edge case coverage and fuzz testing"

  - name: "Adapter Correctness & Key Collision"
    description: "Do adapters correctly distinguish between tldr/cheat entries and gem entries? Is the shared gem_name upsert key causing data collisions? Are namespace boundaries maintained between different content types?"
    scale: "1-5"
    weight: 0.14
    instruction: "Check adapter upsert logic for key collision scenarios. Verify tldr/cheat entries cannot overwrite gem entries. Examine namespace separation in data flow. Cite adapter files and upsert queries."
    score_definitions:
      1: "Frequent key collisions; no namespace separation; data corruption possible"
      2: "Shared gem_name key allows tldr/cheat to collide with gem entries (CURRENT STATE)"
      3: "Collision scenarios identified but not prevented; partial namespace separation"
      4: "Clean namespace separation; collision prevention implemented; evidence of boundary testing"
      5: "Robust multi-tenant design with comprehensive collision prevention and audit trails"

  - name: "Error Handling & Resilience"
    description: "Are circuit breakers properly configured and reused? Are timeouts set for external calls? Is connection pooling managed correctly? Are error paths handled at all external boundaries (HTTP, DB, LLM)?"
    scale: "1-5"
    weight: 0.16
    instruction: "Verify circuit breakers are singleton/reused instances (not recreated per call). Check Sequel connection management for leaks. Validate timeout configuration for HTTP and LLM calls. Examine error handling at each external boundary."
    score_definitions:
      1: "No circuit breakers; connection leaks; no timeout configuration; bare rescues"
      2: "Circuit breakers recreated per call (defeats purpose); connection leak from repeated Sequel.connect (CURRENT STATE)"
      3: "Circuit breakers functional; connection pooling improved; timeouts configured for critical paths"
      4: "Comprehensive error handling; reusable circuit breakers; connection pool managed; evidence of failure testing"
      5: "Defense-in-depth with circuit breakers, timeouts, retries, and structured error types"

  - name: "Convention Compliance"
    description: "Does the code follow StandardRB conventions consistently? Are line counts reasonable (no god classes)? Is namespacing correct per Zeitwerk conventions? Are frozen_string_literal comments present?"
    scale: "1-5"
    weight: 0.12
    instruction: "Run StandardRB linter and note violations. Check file sizes (>200 lines is a signal). Verify Zeitwerk path/constant correspondence. Confirm frozen_string_literal on all .rb files. Check for duplicate requires."
    score_definitions:
      1: "Pervasive StandardRB violations; god classes; Zeitwerk mismatches; missing frozen_string_literal"
      2: "Several violations; duplicate requires; cross-namespace requires; line count issues (CURRENT STATE)"
      3: "Most conventions followed; isolated violations; evidence of which files checked"
      4: "StandardRB-clean; proper namespacing; reasonable file sizes; evidence of linting"
      5: "Convention-compliant plus proactive style improvements beyond minimum"

  - name: "Test Coverage"
    description: "Does the test suite cover critical paths including parser edge cases, adapter collision scenarios, and CLI wiring? Are integration tests present for the full data flow?"
    scale: "1-5"
    weight: 0.12
    instruction: "Examine test files for coverage of: parser edge cases, adapter key collisions, CLI argument handling, Rakefile tasks, error paths. Check for integration tests covering full data flow from fetch to search."
    score_definitions:
      1: "No tests or trivial coverage; critical paths untested"
      2: "Superficial test coverage; parser edge cases untested; no integration tests (CURRENT STATE)"
      3: "Core paths tested; edge cases partially covered; some integration testing"
      4: "Comprehensive coverage including edge cases and integration flows; evidence of test quality"
      5: "Production-grade test suite with mutation testing and property-based testing"

  - name: "Integration Readiness"
    description: "Is the CLI properly wired with argument handling? Do Rakefile tasks work correctly with valid inputs? Is the generate task protected against nil inputs? Are all entry points validated?"
    scale: "1-5"
    weight: 0.06
    instruction: "Test CLI argument parsing. Verify Rakefile generate task handles missing vector/gem_names gracefully. Check that all entry points validate inputs before processing. Examine error messages for user clarity."
    score_definitions:
      1: "CLI broken; Rakefile tasks crash on valid inputs; no input validation"
      2: "Generate task crashes with nil.map; missing input validation on entry points (CURRENT STATE)"
      3: "CLI functional; Rakefile tasks work with valid inputs; basic validation present"
      4: "Robust CLI with comprehensive argument validation; Rakefile tasks protected; clear error messages"
      5: "Production-ready CLI with subcommands, help text, and comprehensive input validation"

  - name: "SourceFetch Reliability"
    description: "Does SourceFetch construct correct URLs for all source types? Are branch names included where required? Is the .md extension stripping consistent? Are fetch errors handled gracefully?"
    scale: "1-5"
    weight: 0.06
    instruction: "Verify URL construction for tldr, cheat, and gem sources. Check that branch names are included in URLs. Confirm .md extension stripping for cheat pages. Test error handling for missing pages and network failures."
    score_definitions:
      1: "URLs malformed; missing branch names; no error handling for fetch failures"
      2: "SourceFetch URL missing branch name; .md extension not stripped for cheat (CURRENT STATE)"
      3: "URLs correct for primary sources; branch names included; basic error handling"
      4: "Comprehensive URL construction; all sources tested; robust error handling with retries"
      5: "Production-grade fetch with CDN fallback, caching, and comprehensive error recovery"
```

## Checklist

```yaml
checklist:
  # Schema & Migration (8 items)
  - id: "CK-SM-001"
    dimension: "Schema & Migration Correctness"
    question: "Does Schema.ensure execute ALL migrations (001 AND 002) at runtime?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Both migration 001 and 002 execute when Schema.ensure is called"
    fail_criteria: "Only migration 001 executes; migration 002 columns missing at runtime"
    rationale: "Critical issue I1: migration 002 never executes, leaving source/platform/raw_content_hash columns absent"

  - id: "CK-SM-002"
    dimension: "Schema & Migration Correctness"
    question: "Does the raw_content_hash unique constraint coexist peacefully with gem_name unique constraint?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Both constraints can be satisfied simultaneously without conflicts"
    fail_criteria: "Unique constraint conflicts when inserting records with same raw_content_hash or gem_name"
    rationale: "Critical issue I2: dual-identity design causes constraint conflicts"

  - id: "CK-SM-003"
    dimension: "Schema & Migration Correctness"
    question: "Are migration 002 columns (source, platform, raw_content_hash) present in the schema after migration?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "All three columns exist and are queryable after Schema.ensure completes"
    fail_criteria: "Columns missing or schema doesn't reflect migration 002 changes"
    rationale: "Migration 002 adds critical columns for content tracking"

  - id: "CK-SM-004"
    dimension: "Schema & Migration Correctness"
    question: "Is the migration order deterministic and idempotent?"
    category: "principle"
    importance: "important"
    pass_criteria: "Running Schema.ensure multiple times produces same result without errors"
    fail_criteria: "Repeated runs cause errors or duplicate migrations"
    rationale: "Idempotent migrations prevent deployment issues"

  - id: "CK-SM-005"
    dimension: "Schema & Migration Correctness"
    question: "Does the schema support the intended query patterns (keyword search, vector search, source filtering)?"
    category: "principle"
    importance: "important"
    pass_criteria: "All required indexes exist for query patterns; pg_trgm extension enabled"
    fail_criteria: "Missing indexes cause slow queries; pg_trgm not available"
    rationale: "Schema must support both search modalities efficiently"

  - id: "CK-SM-006"
    dimension: "Schema & Migration Correctness"
    question: "Are there any foreign key constraints or referential integrity rules missing?"
    category: "principle"
    importance: "optional"
    pass_criteria: "Referential integrity maintained where relationships exist"
    fail_criteria: "Orphaned records possible due to missing foreign keys"
    rationale: "Data integrity depends on proper constraint design"

  - id: "CK-SM-007"
    dimension: "Schema & Migration Correctness"
    question: "Does the schema handle NULL values gracefully for optional fields?"
    category: "principle"
    importance: "important"
    pass_criteria: "Optional fields allow NULL; queries handle NULL correctly"
    fail_criteria: "NULL values cause query errors or unexpected behavior"
    rationale: "Source/platform may be NULL for gem entries"

  - id: "CK-SM-008"
    dimension: "Schema & Migration Correctness"
    question: "Is there a rollback strategy for migrations?"
    category: "principle"
    importance: "optional"
    pass_criteria: "Migration down methods exist or migration is documented as irreversible"
    fail_criteria: "No rollback capability and no documentation of irreversibility"
    rationale: "Deployment safety requires migration rollback options"

  # Parser Correctness (6 items)
  - id: "CK-PR-001"
    dimension: "Parser Correctness"
    question: "Does the tldr parser extract the actual command name (not description text)?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "command_name returns the command identifier (e.g., 'ls', 'git')"
    fail_criteria: "command_name returns description text instead of command name"
    rationale: "Critical issue I3: command_name extraction returns wrong field"

  - id: "CK-PR-002"
    dimension: "Parser Correctness"
    question: "Does the tldr example regex handle real-world page variations?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Examples parse correctly from diverse tldr pages including edge cases"
    fail_criteria: "Example regex too strict; fails on valid tldr pages"
    rationale: "Critical issue I4: regex too strict for real-world pages"

  - id: "CK-PR-003"
    dimension: "Parser Correctness"
    question: "Does the cheat parser frontmatter removal preserve content with --- in code blocks?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Content with --- delimiters in code blocks remains intact after frontmatter removal"
    fail_criteria: "Frontmatter removal corrupts content containing --- in code blocks"
    rationale: "High issue I5: frontmatter removal can corrupt legitimate content"

  - id: "CK-PR-004"
    dimension: "Parser Correctness"
    question: "Does the cheat parser strip .md extension from command names?"
    category: "principle"
    importance: "important"
    pass_criteria: "Command names are clean without .md extension"
    fail_criteria: "Command names retain .md extension"
    rationale: "Medium issue I21: .md extension not stripped"

  - id: "CK-PR-005"
    dimension: "Parser Correctness"
    question: "Do parsers handle empty or malformed input gracefully?"
    category: "principle"
    importance: "important"
    pass_criteria: "Empty/malformed input returns empty result or raises descriptive error"
    fail_criteria: "Parsers crash or return garbage on malformed input"
    rationale: "Robust parsers must handle edge cases gracefully"

  - id: "CK-PR-006"
    dimension: "Parser Correctness"
    question: "Are parser outputs validated before database insertion?"
    category: "principle"
    importance: "important"
    pass_criteria: "Parsed data validated against expected schema before insertion"
    fail_criteria: "Unvalidated parser output inserted directly into database"
    rationale: "Data quality depends on validation at insertion boundary"

  # Adapter Correctness & Key Collision (4 items)
  - id: "CK-AD-001"
    dimension: "Adapter Correctness & Key Collision"
    question: "Does the shared gem_name upsert key prevent tldr/cheat entries from colliding with gem entries?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "tldr/cheat entries use distinct keys that cannot collide with gem entries"
    fail_criteria: "Shared gem_name key allows cross-type collisions"
    rationale: "High issue I6: shared upsert key causes data collision risk"

  - id: "CK-AD-002"
    dimension: "Adapter Correctness & Key Collision"
    question: "Are namespace boundaries maintained between different content types in the database?"
    category: "hard_rule"
    importance: "important"
    pass_criteria: "Each content type has distinct namespace or source identifier"
    fail_criteria: "Content types share namespace without distinction"
    rationale: "Namespace separation prevents data confusion"

  - id: "CK-AD-003"
    dimension: "Adapter Correctness & Key Collision"
    question: "Does the adapter handle duplicate content gracefully (idempotent upserts)?"
    category: "principle"
    importance: "important"
    pass_criteria: "Repeated upserts of same content produce no errors or duplicates"
    fail_criteria: "Duplicate content causes errors or creates duplicate records"
    rationale: "Idempotent operations are essential for reliable data pipelines"

  - id: "CK-AD-004"
    dimension: "Adapter Correctness & Key Collision"
    question: "Are adapter methods coupled to GemPatterns::VERSION or other external constants?"
    category: "principle"
    importance: "important"
    pass_criteria: "Adapters are decoupled from external version constants"
    fail_criteria: "Adapters depend on GemPatterns::VERSION or similar external constants"
    rationale: "Medium issue I19: coupling to external constants reduces portability"

  # Error Handling & Resilience (5 items)
  - id: "CK-EH-001"
    dimension: "Error Handling & Resilience"
    question: "Are circuit breakers reused as singletons rather than recreated per call?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Circuit breaker instances are reused across calls (singleton or class-level)"
    fail_criteria: "New circuit breaker created for each call (defeats state tracking)"
    rationale: "Medium issues I10/I11: recreated circuit breakers lose state"

  - id: "CK-EH-002"
    dimension: "Error Handling & Resilience"
    question: "Is Sequel connection management leak-free (no repeated Sequel.connect calls)?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Single connection pool established; no repeated connect calls"
    fail_criteria: "Repeated Sequel.connect calls cause connection leaks"
    rationale: "Medium issue I13: connection leak from repeated connects"

  - id: "CK-EH-003"
    dimension: "Error Handling & Resilience"
    question: "Are timeouts configured for all external calls (HTTP, LLM, database)?"
    category: "hard_rule"
    importance: "important"
    pass_criteria: "All external calls have explicit timeout configuration"
    fail_criteria: "External calls can hang indefinitely without timeout"
    rationale: "Timeouts prevent resource exhaustion from unresponsive services"

  - id: "CK-EH-004"
    dimension: "Error Handling & Resilience"
    question: "Is the global RubyLLM configuration side-effect isolated or documented?"
    category: "principle"
    importance: "important"
    pass_criteria: "RubyLLM configuration is isolated to this tool or side effects are explicitly documented"
    fail_criteria: "Global RubyLLM configuration affects other tools without warning"
    rationale: "Medium issue I12: global configuration side effect"

  - id: "CK-EH-005"
    dimension: "Error Handling & Resilience"
    question: "Are error messages user-friendly at CLI boundaries?"
    category: "principle"
    importance: "optional"
    pass_criteria: "Errors display clear, actionable messages to users"
    fail_criteria: "Raw exceptions or stack traces exposed to users"
    rationale: "CLI tools should provide helpful error messages"

  # Convention Compliance (4 items)
  - id: "CK-CC-001"
    dimension: "Convention Compliance"
    question: "Does every .rb file begin with # frozen_string_literal: true?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "All .rb files have frozen_string_literal comment on line 1"
    fail_criteria: "Any .rb file missing frozen_string_literal comment"
    rationale: "StandardRB requirement; absence causes string allocation waste"

  - id: "CK-CC-002"
    dimension: "Convention Compliance"
    question: "Does the code pass StandardRB linting with zero violations?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "standardrb command exits with zero violations"
    fail_criteria: "StandardRB reports any violations"
    rationale: "Convention target is StandardRB; code must be clean"

  - id: "CK-CC-003"
    dimension: "Convention Compliance"
    question: "Are there any duplicate requires or cross-namespace requires?"
    category: "principle"
    importance: "important"
    pass_criteria: "No duplicate requires; no cross-namespace requires"
    fail_criteria: "Duplicate requires present or cross-namespace requires exist"
    rationale: "Low issues I18/I22: duplicate and cross-namespace requires"

  - id: "CK-CC-004"
    dimension: "Convention Compliance"
    question: "Are file sizes reasonable (no files >200 lines without justification)?"
    category: "principle"
    importance: "important"
    pass_criteria: "All files under 200 lines or large files have documented justification"
    fail_criteria: "Files exceed 200 lines without clear reason"
    rationale: "Large files indicate potential god class or missing decomposition"

  # Test Coverage (3 items)
  - id: "CK-TC-001"
    dimension: "Test Coverage"
    question: "Do tests cover parser edge cases (malformed input, empty pages, special characters)?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Tests exist for parser edge cases and verify correct behavior"
    fail_criteria: "Parser edge cases untested or tests don't cover failure modes"
    rationale: "Medium issue I17: superficial test coverage"

  - id: "CK-TC-002"
    dimension: "Test Coverage"
    question: "Do tests cover adapter key collision scenarios?"
    category: "hard_rule"
    importance: "important"
    pass_criteria: "Tests verify that tldr/cheat entries don't collide with gem entries"
    fail_criteria: "No tests for key collision scenarios"
    rationale: "Key collisions are a critical data integrity risk"

  - id: "CK-TC-003"
    dimension: "Test Coverage"
    question: "Are integration tests present for the full data flow (fetch → parse → embed → search)?"
    category: "principle"
    importance: "important"
    pass_criteria: "Integration tests cover end-to-end data flow"
    fail_criteria: "Only unit tests exist; no integration testing"
    rationale: "Full data flow testing catches integration issues"

  # Integration Readiness (3 items)
  - id: "CK-IR-001"
    dimension: "Integration Readiness"
    question: "Does the Rakefile generate task handle nil/empty inputs gracefully?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "Generate task validates inputs before processing; no nil.map crashes"
    fail_criteria: "Generate task crashes with nil.map when called without gem_names"
    rationale: "High issue I9: nil.map crash on missing inputs"

  - id: "CK-IR-002"
    dimension: "Integration Readiness"
    question: "Is the CLI argument parsing robust with helpful error messages?"
    category: "principle"
    importance: "important"
    pass_criteria: "CLI provides clear error messages for invalid arguments"
    fail_criteria: "CLI crashes or provides unhelpful errors for invalid input"
    rationale: "CLI tools must handle user input gracefully"

  - id: "CK-IR-003"
    dimension: "Integration Readiness"
    question: "Are all entry points (CLI, Rake, direct API) validated for input safety?"
    category: "principle"
    importance: "important"
    pass_criteria: "All entry points validate inputs before processing"
    fail_criteria: "Some entry points accept invalid input without validation"
    rationale: "Input validation at all boundaries prevents runtime errors"

  # SourceFetch Reliability (3 items)
  - id: "CK-SF-001"
    dimension: "SourceFetch Reliability"
    question: "Does SourceFetch include branch names in URLs where required?"
    category: "hard_rule"
    importance: "essential"
    pass_criteria: "URLs include correct branch names for all source types"
    fail_criteria: "URLs missing branch names cause 404 errors"
    rationale: "Medium issue I14: URL missing branch name"

  - id: "CK-SF-002"
    dimension: "SourceFetch Reliability"
    question: "Does SourceFetch strip .md extension from cheat page names?"
    category: "principle"
    importance: "important"
    pass_criteria: "Cheat page names are clean without .md extension"
    fail_criteria: "Cheat page names retain .md extension"
    rationale: "Medium issue I21: .md extension not stripped"

  - id: "CK-SF-003"
    dimension: "SourceFetch Reliability"
    question: "Are fetch errors handled gracefully with retry logic?"
    category: "principle"
    importance: "important"
    pass_criteria: "Fetch errors trigger retries with exponential backoff"
    fail_criteria: "Fetch errors fail immediately without retry"
    rationale: "Network reliability requires retry logic"
```

## Scoring Metadata

```yaml
scoring:
  aggregation: "weighted_sum"
  essential_checklist_cap: true
  cap_score: 2.0
  pitfall_penalty: 0.3
  pass_threshold: 3.5
  total_weight: 1.0
  note: "If any essential checklist item = FAIL, overall score cannot exceed 2.0. Each pitfall item = YES deducts 0.3 from weighted sum."

weights_summary:
  Schema & Migration Correctness: 0.18
  Parser Correctness: 0.16
  Adapter Correctness & Key Collision: 0.14
  Error Handling & Resilience: 0.16
  Convention Compliance: 0.12
  Test Coverage: 0.12
  Integration Readiness: 0.06
  SourceFetch Reliability: 0.06
  total: 1.00

checklist_summary:
  total_items: 36
  essential_items: 12
  important_items: 19
  optional_items: 5
  by_dimension:
    Schema & Migration Correctness: 8
    Parser Correctness: 6
    Adapter Correctness & Key Collision: 4
    Error Handling & Resilience: 5
    Convention Compliance: 4
    Test Coverage: 3
    Integration Readiness: 3
    SourceFetch Reliability: 3
```

## Calibration Notes

```yaml
calibration:
  project_type: "CLI tool"
  scope: "Local development utility, not distributed system"
  critical_priorities:
    - "Fix migration 002 execution (I1) - blocks schema completeness"
    - "Resolve constraint conflicts (I2) - blocks data integrity"
    - "Fix tldr command_name extraction (I3) - blocks core functionality"
    - "Fix tldr example regex (I4) - blocks content parsing"
  de_emphasized:
    - "Distributed system patterns (circuit breakers are nice-to-have, not essential)"
    - "High availability requirements (single-user tool)"
    - "Complex deployment patterns (local CLI tool)"
  emphasis:
    - "Parser correctness is paramount - this is a content processing tool"
    - "Data integrity (no collisions, correct schema) is critical"
    - "CLI usability (clear errors, robust input handling) is important"
    - "Test coverage should focus on parser edge cases and data flow"
  context:
    current_health: "6.5/10"
    total_issues: 32
    critical: 4
    high: 7
    medium: 9
    low: 2
    files: 33
    loc: "~1,030"
```

## Execution Instructions

```yaml
execution:
  evaluator: "compliance-guardrail-agent"
  mode: "sift_report"
  steps:
    - "Load this specification from scratchpad"
    - "For each checklist item, examine the relevant code files"
    - "Score each dimension 1-5 based on evidence found"
    - "Apply essential cap if any essential item fails"
    - "Apply pitfall penalty for each pitfall item triggered"
    - "Calculate weighted sum and compare to pass_threshold (3.5)"
    - "Generate report with findings, scores, and recommendations"
  files_to_examine:
    - "lib/tldr_cli/schema.rb (migrations, constraints)"
    - "lib/tldr_cli/parsers/tldr_parser.rb (command_name, examples)"
    - "lib/tldr_cli/parsers/cheat_parser.rb (frontmatter, .md stripping)"
    - "lib/tldr_cli/adapters/*.rb (upsert logic, key collision)"
    - "lib/tldr_cli/circuit_breaker.rb (singleton pattern)"
    - "lib/tldr_cli/db.rb (connection management)"
    - "lib/tldr_cli/source_fetch.rb (URL construction, branch names)"
    - "Rakefile (generate task, input validation)"
    - "spec/ (test coverage analysis)"
```