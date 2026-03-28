---
name: codestyle-review
description: Code style review criteria for Java, Angular, and infrastructure files
---

# Code Style Review Skill

## Core Philosophy

**Readability is king.** Code is read far more often than it is written. Every style rule exists to make the code easier to read, understand, and maintain.

## Language Rule

ALL code elements MUST be in English, including domain terms. Variable names, method names, class names, comments, commit messages, and documentation must all be in English. Flag any non-English identifiers or domain terms in code.

## Core Review Process

1. **Read changes** — Understand the full scope of the diff. Identify all files touched and their languages/types.
2. **Check naming per language** — Verify naming conventions are followed for the specific language. See `references/java-conventions.md` and `references/angular-conventions.md`.
3. **Check formatting and imports** — Verify import organization, whitespace, indentation, and formatting rules. See language-specific references.
4. **Assess readability** — Apply the cross-language readability checks below.
5. **Check consistency** — Verify the changes are consistent with the existing codebase style. New code should not introduce a different style.

## Reference Guide

| Topic                        | Reference File                              |
|------------------------------|---------------------------------------------|
| Java Conventions             | `references/java-conventions.md`            |
| Angular Conventions          | `references/angular-conventions.md`         |
| Infrastructure Conventions   | `references/infrastructure-conventions.md`  |

## Readability Checks (Cross-Language)

These apply to all languages:

- **Method length** — Flag methods longer than approximately 30 lines. Suggest extraction of logical blocks.
- **Nesting depth** — Flag nesting deeper than 3 levels (e.g., if inside if inside for inside if). Suggest early returns, guard clauses, or extraction.
- **Naming clarity** — Names should reveal intent. Flag single-letter variables (except loop counters), abbreviations, or ambiguous names.
- **Consistency** — Similar concepts should be named and structured similarly throughout the codebase.
- **No clever code** — Flag overly terse expressions, obscure language features used for brevity, or "golf-style" code. Prefer explicit and obvious over clever and compact.
- **Dead code** — Flag commented-out code, unused variables, unused imports, and unreachable code.

## Output Format

Report findings using the following severity levels:

- **Issue** — Style violation that reduces readability or violates project conventions. Should be fixed before merge.
- **Nitpick** — Minor style preference or cosmetic improvement. Not blocking, but would improve consistency.

Each finding must include: severity, file and line reference, description of the issue, and a concrete suggestion.
