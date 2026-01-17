---
name: debugging-framework
description: Systematic 4-phase debugging approach for finding root causes instead of treating symptoms.
---

# Debugging Framework Skill

## Purpose

This skill provides a systematic, 4-phase debugging framework that ensures you find and fix root causes rather than applying workarounds or treating symptoms.

## When to Use

Invoke this skill when:
- Debugging any technical issue (bugs, errors, failures, performance problems)
- Investigating why something isn't working as expected
- User reports unexpected behavior or errors
- Tests are failing
- Services are experiencing issues

## Core Principle

**YOU MUST ALWAYS find the root cause of any issue you are debugging.**

**YOU MUST NEVER fix a symptom or add a workaround instead of finding a root cause, even if it is faster.**

## The 4-Phase Framework

### Phase 1: Root Cause Investigation (BEFORE attempting fixes)

**Read Error Messages Carefully**: Don't skip past errors or warnings - they often contain the exact solution

**Reproduce Consistently**: Ensure you can reliably reproduce the issue before investigating

**Check Recent Changes**: What changed that could have caused this? Git diff, recent commits, etc.

### Phase 2: Pattern Analysis

**Find Working Examples**: Locate similar working code in the same codebase

**Compare Against References**: If implementing a pattern, read the reference implementation completely

**Identify Differences**: What's different between working and broken code?

**Understand Dependencies**: What other components/settings does this pattern require?

### Phase 3: Hypothesis and Testing

**Form Single Hypothesis**: What do you think is the root cause? State it clearly

**Test Minimally**: Make the smallest possible change to test your hypothesis

**Verify Before Continuing**: Did your test work? If not, form new hypothesis - don't add more fixes

**When You Don't Know**: Say "I don't understand X" rather than pretending to know

### Phase 4: Implementation Rules

**ALWAYS have the simplest possible failing test case**. If there's no test framework, it's ok to write a one-off test script.

**NEVER add multiple fixes at once**

**NEVER claim to implement a pattern without reading it completely first**

**ALWAYS test after each change**

**IF your first fix doesn't work, STOP and re-analyze rather than adding more fixes**

## Example Workflow

```
User: "The login endpoint is returning 500 errors"

Phase 1 - Investigation:
- Read the full error message and stack trace
- Attempt to reproduce: curl the endpoint, observe the exact error
- Check git log: what changed in the last few commits?

Phase 2 - Pattern Analysis:
- Find working endpoint: /api/register works fine
- Compare implementations: what's different?
- Check dependencies: does login need database, cache, or external service?

Phase 3 - Hypothesis:
- Hypothesis: "The login endpoint is missing database connection config"
- Test minimally: Add logging to verify database connection status
- Result: Logging shows database connection fails

Phase 4 - Implementation:
- Write test: test_login_endpoint_connects_to_database()
- Apply single fix: Add missing DATABASE_URL environment variable
- Verify: Run test, it passes. Run endpoint, it works.
- Done: Root cause found and fixed
```

## Anti-Patterns to Avoid

**Shotgun Debugging**: Making multiple changes at once hoping something works
- ❌ "Let me try adding error handling AND changing the timeout AND updating the config"
- ✅ "Let me test if the timeout is the issue by only changing that"

**Symptom Treatment**: Fixing what's visible without understanding why
- ❌ "The error says 'null pointer', so I'll just add a null check"
- ✅ "Why is this null? It shouldn't be. Let me trace where it comes from"

**Pattern Cargo-Culting**: Copying code without understanding it
- ❌ "I'll copy this auth pattern from Stack Overflow without reading how it works"
- ✅ "Let me read and understand this auth pattern, then adapt it to our needs"

**Assumption-Based Fixing**: Guessing without evidence
- ❌ "I assume it's a race condition, let me add sleeps everywhere"
- ✅ "Let me add logging to see if requests are actually overlapping"

## Integration with Testing

When debugging, testing is critical:

1. **Create minimal reproducer**: Simplest possible test case that shows the bug
2. **Use as verification**: Test should fail before fix, pass after fix
3. **Keep for regression**: Commit the test to prevent bug from returning

If there's no test framework in the project, write a simple script:

```python
# test_bug.py - Reproduces login 500 error
import requests
response = requests.post("http://localhost:8000/api/login", json={"user": "test"})
assert response.status_code == 200, f"Expected 200, got {response.status_code}"
print("✓ Test passed")
```

---

Remember: The goal is understanding and fixing root causes, not applying quick patches. Take the time to investigate properly.
