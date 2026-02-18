---
name: commit-messages
description: Write git commit messages following conventional commits standard. Use when creating git commits via Bash tool (git commit) or reviewing commit messages.
model: haiku
---

# Conventional Commits Standard

## Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only
- **style**: Code style (formatting, missing semi colons, etc)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes to build system or dependencies
- **ci**: CI configuration changes
- **chore**: Other changes that don't modify src or test files

## Rules
- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at the end
- Keep description under 50 characters
- Body explains WHY, not WHAT (code shows what)
- Focus on the purpose and impact, not implementation details

## Examples
```
feat(bigquery): add streaming insert support
fix(terraform): correct dataset location variable
test(main): add integration tests for data pipeline
refactor: simplify error handling in api client
docs: update README with setup instructions
```

## Breaking Changes
Use `!` after type/scope and add BREAKING CHANGE footer:
```
feat(api)!: remove deprecated endpoints

BREAKING CHANGE: GET /v1/old-endpoint has been removed. Use /v2/new-endpoint instead.
```

## When Writing Commits
1. Review `git diff --staged` to understand what changed
2. Identify the primary purpose (feat, fix, refactor, etc.)
3. Write a clear description of WHY the change was made
4. Keep it concise - the code shows the details
