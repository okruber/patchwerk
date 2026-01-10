---
name: cleanup
description: Scan codebase for bloat and unused code. Use after completing features, before commits, or on demand.
---

# Code Cleanup & Bloat Detection Skill

## Purpose

This skill identifies and removes code bloat - unused code, over-abstractions, outdated tests, and unnecessary complexity that accumulates during development.

## When to Use

Invoke this skill:
- After completing a feature or refactoring
- Before creating a commit or PR
- When you suspect code bloat exists
- On demand when the user asks for cleanup
- As `/cleanup` command

## Detection Rules

### 1. Unused Code Detection

**Search for:**
- Unused imports (Python: `import X` but X never used; JS/TS: similar patterns)
- Unused functions (defined but never called)
- Unused classes (defined but never instantiated)
- Unused variables (assigned but never read)
- Commented-out code blocks

**How to detect:**
- Use Grep to find function/class definitions
- Cross-reference with calls/usage
- Flag items with zero references
- Check git history - if recently added and unused, likely bloat

### 2. Single-Use Abstractions

**Search for:**
- Helper functions called exactly once
- Wrapper classes with single usage
- Configuration systems used for one value
- Utility modules with one caller

**How to detect:**
- Find all function calls for each defined function
- If call count = 1, flag as candidate for inlining
- Check if abstraction adds clarity vs adds indirection

**Report format:**
```
SINGLE-USE HELPER: function_name() in file.py:42
  - Called once from: other_file.py:156
  - Recommendation: Inline this function at call site
```

### 3. Over-Engineering Patterns

**Search for:**
- Base classes with single implementation
- Interfaces/protocols with one implementer
- Factory patterns for creating one type
- Strategy patterns with single strategy
- Plugin systems with hardcoded plugins

**How to detect:**
- Find class definitions with "Base", "Abstract", "Interface" in name
- Count subclasses/implementations
- If count = 1, flag as premature abstraction

**Report format:**
```
UNNECESSARY ABSTRACTION: BaseProcessor in processor.py:10
  - Only one implementation: DataProcessor
  - Recommendation: Remove base class, use DataProcessor directly
```

### 4. Outdated or Redundant Tests

**Search for:**
- Tests for deleted code (test files referencing non-existent modules/functions)
- Tests that only verify mocked behavior
- Duplicate test cases
- Tests with no assertions

**How to detect:**
- Find test files (test_*.py, *.test.ts, etc.)
- Extract tested module/function names from imports/calls
- Check if those targets still exist
- Read test bodies for `assert` statements - flag if zero assertions

**Report format:**
```
OUTDATED TEST: test_old_feature() in test_api.py:89
  - References: old_api_endpoint() which no longer exists
  - Recommendation: Delete this test
```

### 5. Defensive Code for Impossible Scenarios

**Search for:**
- Error handling for cases that cannot occur
- Validation of internal function calls (vs external boundaries)
- Try/except blocks catching errors that can't happen
- Default values for required parameters

**How to detect:**
- Find try/except or error handling blocks
- Analyze context - is this at system boundary (user input, external API)?
- If internal call with controlled inputs, flag as unnecessary

**Report format:**
```
UNNECESSARY VALIDATION: parameter check in process_data() at data.py:234
  - Validates internal call from trusted code
  - Recommendation: Remove validation, add type hints instead
```

### 6. Dead Configuration

**Search for:**
- Config keys that are never read
- Environment variables defined but not used
- Feature flags with no conditional logic
- Settings with only one possible value

**How to detect:**
- Find config definitions (settings.py, .env, config.json)
- Search codebase for each config key reference
- Flag keys with zero references

**Report format:**
```
UNUSED CONFIG: FEATURE_X_ENABLED in settings.py
  - Never referenced in codebase
  - Recommendation: Delete this setting
```

## Scanning Process

### Phase 1: Quick Scan (Always run this)

1. **Find Python/JS/TS files** with code changes in recent commits
2. **Scan imports**: Flag unused imports
3. **Scan functions**: Count call sites, flag zero-usage and single-use
4. **Scan tests**: Check for references to deleted code

**Output**: Summary of obvious bloat

### Phase 2: Deep Scan (Run if Phase 1 finds issues)

1. **Analyze abstractions**: Find base classes, interfaces, factories
2. **Count implementations**: Flag 1:1 patterns
3. **Review error handling**: Find defensive code in internal logic
4. **Audit configuration**: Find unused settings

**Output**: Detailed report with file:line references

### Phase 3: Cleanup Recommendations (Always provide)

For each issue found:
1. **State the problem**: What bloat was detected
2. **Show location**: file:line reference
3. **Explain impact**: Why it's bloat (unused, over-abstracted, etc.)
4. **Recommend action**: Delete, inline, simplify, or ask user

## Report Format

```markdown
# Code Cleanup Report

## Summary
- X unused imports
- Y single-use helpers
- Z unnecessary abstractions
- N outdated tests
- M unused config values

## Critical Issues (Fix these first)

### Unused Code
1. `unused_function()` in data/processor.py:156
   - Never called anywhere in codebase
   - Action: DELETE

2. `import old_library` in api/main.py:5
   - Library not used in this file
   - Action: DELETE

### Single-Use Abstractions
1. `format_helper()` in utils/format.py:23
   - Called once from reports/generator.py:87
   - Action: INLINE at call site

### Over-Engineering
1. `BaseValidator` in validators/base.py:10
   - Only one implementation: EmailValidator
   - Action: REMOVE base class, use EmailValidator directly

## Minor Issues (Fix if time permits)

[... continue with less critical items ...]

## Files Affected
- data/processor.py (2 issues)
- api/main.py (1 issue)
- utils/format.py (1 issue)

## Recommended Actions
1. Delete X files that are no longer needed
2. Inline Y single-use helpers
3. Remove Z unnecessary abstractions
4. Update or delete N outdated tests
```

## Execution Steps

When user invokes `/cleanup`:

1. **Ask scope**: "Scan entire codebase or recent changes only?"
   - Recent changes: Faster, scans files modified in last N commits
   - Entire codebase: Thorough, but slower

2. **Run Phase 1** (Quick Scan):
   - Use Grep to find unused imports
   - Use Grep to find function definitions
   - Cross-reference with calls
   - Check tests for deleted code

3. **Report Phase 1 findings**:
   - Show summary count
   - Ask: "Found X issues. Run deep scan for abstractions and config?"

4. **If user agrees, run Phase 2** (Deep Scan):
   - Analyze class hierarchies
   - Check for over-engineering patterns
   - Audit configuration

5. **Generate final report** with all findings

6. **Create beads for cleanup tasks**:
   - For each significant issue found, create a bead to track the cleanup work
   - Group similar issues (e.g., all unused imports in one bead if from same area)
   - Use appropriate priority:
     - P2 (medium) for most cleanup tasks
     - P3 (low) for minor improvements like unused imports
     - P1 (high) if bloat is causing real problems (performance, bugs)
   - Set type to "task" for cleanup work

7. **Create beads in parallel**:
   - Use parallel Task tool calls to create multiple beads efficiently
   - Format: `bd create --title="Remove unused X from Y" --type=task --priority=N`
   - Each bead should have clear scope and file references

8. **Report summary**:
   - Show total issues found by category
   - List created beads with their IDs
   - User can then work through cleanup beads as needed

## Important Rules

### DO NOT Remove Without Checking:
- Public API functions (even if not used internally, might be used externally)
- Test fixtures and utilities (might be used by multiple tests)
- Code marked with "# DO NOT DELETE" or similar comments
- Library code (in site-packages, node_modules, etc.)

### Bead Creation Guidelines:
- Create separate beads for unrelated issues (don't mix unused imports with over-engineering)
- Group related issues in one bead (e.g., "Clean up unused imports in api/ module")
- Include file:line references in bead title or description
- Set appropriate priority based on impact
- Use type=task for all cleanup work

### ALWAYS Report:
- What you found (count and categories)
- What beads were created (with IDs)
- Estimated impact of cleanup (files affected, LOC to remove)

## Examples

### Example 1: After Feature Development
```
User: "I just finished the export feature"
Assistant: "Great! Let me run /cleanup to check for any bloat introduced."

[Runs Phase 1 scan on recent changes]

"Found 3 unused imports and 1 single-use helper function in the export module.

Creating cleanup bead..."

[Creates bead: "Clean up unused code in export module"]

"Created bead dpg-abc to track cleanup:
- Remove 3 unused imports (csv, json, typing.Optional)
- Inline format_export_name() - used once
- Location: src/export/processor.py

Run 'bd show dpg-abc' to see details."
```

### Example 2: Before Commit
```
User: "/cleanup"
Assistant: "Scanning codebase for bloat..."

[Phase 1 complete]

"Quick scan found:
- 5 unused imports across 3 files
- 2 single-use helpers
- 1 unused function

Run deep scan for over-engineering patterns? This will check for unnecessary abstractions and unused config."

User: "Yes, run deep scan"

[Phase 2 complete]

"Deep scan found 2 additional issues:
- BaseValidator: abstract class with only one implementation
- OLD_API_URL: config value never used

Creating 3 beads for cleanup work..."

[Creates beads in parallel]

"Created cleanup beads:
- dpg-xyz: Remove unused imports (priority: P3)
- dpg-uvw: Inline single-use helpers (priority: P2)
- dpg-rst: Simplify BaseValidator abstraction (priority: P2)

Total impact: 4 files, ~60 LOC to remove
Run 'bd list --status=open' to see all cleanup tasks."
```

### Example 3: On-Demand Cleanup
```
User: "The utils/ directory feels bloated"
Assistant: "I'll scan the utils/ directory for bloat."

[Scans utils/ specifically]

"Found in utils/:
- format_helper.py: Single function called once - should inline
- base_processor.py: Abstract base with one implementation - over-engineered
- old_converter.py: Entire file unused (187 LOC)

Creating cleanup beads..."

[Creates beads]

"Created 3 cleanup beads:
- dpg-aaa: Delete old_converter.py (priority: P2)
- dpg-bbb: Inline format_helper (priority: P3)
- dpg-ccc: Simplify base_processor abstraction (priority: P2)

High impact: Removing old_converter.py alone eliminates 187 LOC.
Recommend starting with dpg-aaa."
```

## Integration with Code Minimalism Checklist

This skill enforces the Code Minimalism Checklist from CLAUDE.md by:
- Detecting violations after they're written (safety net)
- Providing specific, actionable cleanup steps
- Teaching by example what patterns to avoid

Use this skill as a **secondary defense** after the primary defense of not writing bloat in the first place.

---

Remember: The goal is not perfect code, but maintainable code. Some abstractions are worth keeping even if they have one implementation today. Use judgment and ask the user when in doubt.
