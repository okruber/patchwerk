---
name: observability
description: Debug GCP services using gcloud CLI and MCP tools with optimized queries to minimize token usage.
---

# GCP Observability Skill

## Purpose

This skill provides structured workflows for investigating GCP service issues using gcloud CLI (primary) and MCP tools (when needed) while minimizing token consumption.

## When to Use

Invoke this skill:
- When investigating errors in Cloud Run, Cloud Functions, GCE, or other GCP services
- When analyzing performance issues or latency problems
- When debugging failed executions or deployments
- When user asks to "check logs" or "debug" GCP services
- As `/observability` command

## Tool Selection Strategy

### PRIMARY: gcloud CLI
Use for all log queries - much more token-efficient:
```bash
gcloud logging read 'FILTER' \
  --format='json(timestamp,severity,jsonPayload.message)' \
  --limit=25 \
  --order=asc
```

**Why gcloud is better for logs:**
- You control exactly which fields are returned (via --format)
- Minimal JSON structure
- Typical query: 500-2000 tokens vs 5000-10000 tokens with MCP
- No additional metadata overhead

**Common format patterns:**
- Basic: `--format='json(timestamp,severity,jsonPayload.message)'`
- With labels: `--format='json(timestamp,severity,jsonPayload.message,labels)'`
- Text payload: `--format='json(timestamp,severity,textPayload)'`
- Structured: `--format='json(timestamp,severity,jsonPayload)'`

### SECONDARY: MCP Tools
Reserve MCP for capabilities gcloud doesn't have:
- `list_group_stats` - Error grouping and aggregation (no gcloud equivalent)
- `list_time_series` - Metrics and monitoring data
- `list_traces` / `get_trace` - Distributed tracing
- `list_alerts` - Active alert status
- Cross-project log aggregation

## Core Principles

**Token Management**:
- Always use gcloud CLI with --format for log queries
- Default --limit=25 for exploration, --limit=10 for error checking
- Always use specific filters (severity, time windows, resource labels)
- Summarize findings instead of dumping raw logs
- Stop and optimize if any query returns >5k tokens

**Query Strategy**:
1. Start with tightest possible filters
2. Query small time windows (15-30 minutes)
3. Filter by severity when looking for errors
4. Use execution IDs, job names, or instance IDs when available
5. Use --format to return only needed fields
6. Ask before fetching additional pages

## gcloud Logging Filter Syntax

**Basic structure:**
```bash
gcloud logging read 'FILTER_EXPRESSION' \
  --limit=N \
  --order=asc|desc \
  --format='json(field1,field2.subfield,field3)'
```

**Common filters:**
```bash
# Resource type and labels
resource.type="cloud_run_job"
resource.labels.job_name="dbt-runner"
labels."run.googleapis.com/execution_name"="execution-abc"

# Severity
severity="ERROR"
severity>="WARNING"

# Timestamps
timestamp>="2026-01-09T15:26:00Z"
timestamp>="2026-01-09T15:26:00Z" AND timestamp<"2026-01-09T15:56:00Z"

# Text search
jsonPayload.message:"database connection"
textPayload:"failed"

# Combining filters
resource.type="cloud_run_job" AND severity>="WARNING" AND timestamp>="2026-01-09T15:26:00Z"
```

## Common Workflows

### Workflow 1: Investigate Cloud Run Job Failures

**Goal**: Find why a Cloud Run job failed

**Steps**:
1. **Get recent executions** (if not provided by user):
   ```bash
   gcloud run jobs executions list --job=JOB_NAME --limit=5
   ```

2. **Query logs for specific execution** (15-minute window):
   ```bash
   gcloud logging read 'resource.type="cloud_run_job"
     resource.labels.job_name="JOB_NAME"
     labels."run.googleapis.com/execution_name"="EXECUTION_NAME"
     severity>="WARNING"
     timestamp>="EXECUTION_START_TIME"' \
     --limit=25 \
     --order=asc \
     --format='json(timestamp,severity,jsonPayload.message,textPayload)'
   ```

3. **Analyze and summarize**:
   - Count errors by severity
   - Identify error patterns (same message repeated?)
   - Extract relevant stack traces
   - Note first and last error timestamps

4. **Present findings**:
   ```markdown
   ## Execution: EXECUTION_NAME

   **Status**: Failed at HH:MM:SS
   **Duration**: X minutes

   **Error Summary**:
   - 15 ERROR entries
   - 3 WARNING entries
   - First error at HH:MM:SS

   **Root Cause**: [identified pattern]

   **Example Error**:
   ```
   [timestamp] ERROR: Connection to database failed
   [stack trace excerpt if relevant]
   ```

   **Recommendation**: [actionable fix]
   ```

5. **Only if needed**: Fetch more context
   - Ask user: "Need full logs or trace data?"
   - If yes, expand time window or adjust --format to include more fields

### Workflow 2: Debug Recurring Errors

**Goal**: Understand patterns in recurring errors

**Steps**:
1. **Query recent error group stats** (MCP - no gcloud equivalent):
   ```
   list_group_stats(
     projectName: "projects/PROJECT_ID",
     timeRangePeriod: "PERIOD_6_HOURS",
     order: "COUNT_DESC",
     pageSize: 10
   )
   ```

2. **For top error group, get sample logs** (gcloud):
   ```bash
   gcloud logging read 'severity="ERROR"
     timestamp>="2026-01-09T09:00:00Z"
     jsonPayload.message:"CONNECTION_TIMEOUT"' \
     --limit=10 \
     --order=desc \
     --format='json(timestamp,severity,jsonPayload.message,resource.labels)'
   ```

3. **Analyze pattern**:
   - Frequency (errors per hour)
   - Affected resources (which jobs/instances?)
   - Time correlation (does it happen at specific times?)
   - Impact (is service degraded?)

4. **Present findings**:
   ```markdown
   ## Error Pattern Analysis

   **Error**: [error message]
   **Frequency**: X occurrences in last 6 hours (avg Y per hour)
   **Trend**: Increasing / Stable / Decreasing

   **Affected Resources**:
   - cloud_run_job: dbt-runner (80% of errors)
   - cloud_function: data-processor (20% of errors)

   **Time Pattern**: Peaks at XX:00 (hourly scheduled runs)

   **Likely Cause**: [hypothesis based on pattern]

   **Recommended Investigation**:
   1. [specific next step]
   2. [specific next step]
   ```

### Workflow 3: Performance Investigation (Latency/Slowness)

**Goal**: Identify why service is slow

**Steps**:
1. **Get trace samples** (MCP - richer than gcloud):
   ```
   list_traces(
     projectId: "PROJECT_ID",
     filter: "latency:5s",
     startTime: "-1h",
     pageSize: 10,
     orderBy: "duration desc"
   )
   ```

2. **Analyze slowest trace** (MCP):
   ```
   get_trace(
     projectId: "PROJECT_ID",
     traceId: "TRACE_ID"
   )
   ```

3. **Identify bottlenecks**:
   - Which span took longest?
   - Is it database, external API, or internal processing?
   - Are there sequential operations that could be parallel?

4. **Cross-reference with metrics** (MCP):
   ```
   list_time_series(
     name: "projects/PROJECT_ID",
     filter: 'metric.type="run.googleapis.com/request_latencies"
              resource.labels.service_name="SERVICE_NAME"',
     interval: {
       startTime: "-1h",
       endTime: "now"
     },
     aggregation: {
       alignmentPeriod: "60s",
       perSeriesAligner: "ALIGN_PERCENTILE_95"
     },
     pageSize: 25
   )
   ```

5. **Present findings**:
   ```markdown
   ## Performance Analysis

   **P95 Latency**: X seconds (target: Y seconds)
   **Sample Size**: N slow requests in last hour

   **Bottleneck Identified**:
   - Component: Database query in process_data()
   - Duration: X seconds (80% of total request time)
   - Pattern: Affects all requests to /api/process endpoint

   **Trace Evidence**: [trace ID with breakdown]

   **Recommendation**: [specific optimization - add index, cache, etc.]
   ```

### Workflow 4: Resource Health Check

**Goal**: Quick health overview of a service

**Steps**:
1. **Check recent errors** (gcloud):
   ```bash
   # Count errors
   gcloud logging read 'resource.type="cloud_run_job"
     resource.labels.job_name="JOB_NAME"
     severity="ERROR"
     timestamp>="2026-01-09T14:00:00Z"' \
     --limit=1000 \
     --format='value(severity)' | wc -l

   # Sample errors
   gcloud logging read 'resource.type="cloud_run_job"
     resource.labels.job_name="JOB_NAME"
     severity="ERROR"
     timestamp>="2026-01-09T14:00:00Z"' \
     --limit=5 \
     --order=desc \
     --format='json(timestamp,jsonPayload.message)'
   ```

2. **Check active alerts** (MCP):
   ```
   list_alerts(
     parent: "projects/PROJECT_ID",
     filter: 'state="OPEN"',
     pageSize: 10
   )
   ```

3. **Check key metrics** (MCP):
   ```
   list_time_series(
     name: "projects/PROJECT_ID",
     filter: 'metric.type="run.googleapis.com/request_count"
              resource.labels.service_name="SERVICE_NAME"',
     interval: {
       startTime: "-1h",
       endTime: "now"
     },
     aggregation: {
       alignmentPeriod: "60s",
       perSeriesAligner: "ALIGN_RATE"
     },
     pageSize: 25
   )
   ```

4. **Present health summary**:
   ```markdown
   ## Service Health: SERVICE_NAME

   **Status**: Healthy / Degraded / Down

   **Last Hour**:
   - Errors: X (down from Y in previous hour)
   - Requests: N req/min (normal: M req/min)
   - Active Alerts: Z

   **Current Issues**:
   - [Issue 1 if any]
   - [Issue 2 if any]

   **Action Required**: [Yes/No + what to do]
   ```

## Query Optimization Rules

### gcloud --limit Guidelines:
- **Start small** (10): Initial error checking, quick samples
- **Medium** (25): General exploration, execution logs (default)
- **Larger** (50-100): Statistical analysis, comprehensive view
- **ONLY after asking user**: Limits >100

### gcloud --format Guidelines:
**Minimize token usage by selecting only needed fields:**

```bash
# Minimal - just messages
--format='json(timestamp,severity,jsonPayload.message)'

# Include resource info
--format='json(timestamp,severity,jsonPayload.message,resource.labels.job_name)'

# Full payload when needed
--format='json(timestamp,severity,jsonPayload)'

# Text logs
--format='json(timestamp,severity,textPayload)'
```

### Time Window Guidelines:
- **Start narrow** (15-30 minutes for specific executions)
- **Expand cautiously** (to 1-6 hours for pattern analysis)
- **Daily/weekly** only for trends or statistics
- **Always** use ISO 8601 format: `timestamp>="2026-01-09T15:26:00Z"`

### Filter Specificity:
Always include at minimum:
1. Resource type: `resource.type="cloud_run_job"`
2. Time window: `timestamp>="..."`
3. Severity (when debugging): `severity>="WARNING"`
4. Resource identifier: `resource.labels.job_name="..."`

## Response Formatting

**DO**:
- Count and categorize before showing examples
- Use tables for structured data
- Show 1-3 representative log entries, not dozens
- Include actionable recommendations
- Highlight patterns and trends

**DON'T**:
- Dump raw JSON logs
- Show every log entry
- Include verbose stack traces unless relevant
- Repeat similar error messages
- Show debug-level logs unless specifically requested

## Integration with Debugging Framework

This skill follows the debugging framework from CLAUDE.md:

**Phase 1 (Investigation)**:
- Read error messages from logs carefully
- Identify when issue started (timestamp analysis)
- Check what changed (compare with successful executions)

**Phase 2 (Pattern Analysis)**:
- Find working executions (successful runs before failure)
- Compare logs between working and failing executions
- Identify differences (new errors, missing steps, timing changes)

**Phase 3 (Hypothesis)**:
- Form hypothesis from log patterns
- State it clearly to user
- Suggest minimal test (rerun with fix, check specific config, etc.)

**Phase 4 (Implementation)**:
- Never fix multiple potential issues at once
- Test hypothesis with targeted changes
- Verify with new logs/metrics

## Example Invocations

### Example 1: Job Failed
```
User: "dbt-runner job failed, can you check what happened?"
Assistant: "Let me check the logs for the most recent execution."

[Gets execution list, identifies failed execution]
[Uses gcloud logging read with targeted filter, --limit=25]

"Found the issue:

Execution dbt-runner-xyz failed at 14:32:15.

**Root Cause**: Missing environment variable DBT_PROFILES_DIR

**Error**:
```
14:32:14 ERROR: Could not find profiles.yml
```

**Recommendation**: Add DBT_PROFILES_DIR=/dbt to job environment variables."
```

### Example 2: Performance Issue
```
User: "API responses are slow, can you investigate?"
Assistant: "I will analyze recent traces and metrics."

[Uses MCP list_traces with latency filter, pageSize=10]
[Gets detailed trace for slowest request via MCP get_trace]
[Uses gcloud to check for related errors in logs]

"Performance Analysis:

**P95 Latency**: 8.2s (target: <2s)
**Bottleneck**: Database query in user_lookup() taking 7.1s (86% of request time)

**Trace ID**: abc123 shows:
- API handler: 0.1s
- user_lookup query: 7.1s  <- BOTTLENECK
- Response formatting: 0.3s

**Recommendation**: Add index on users.email column - this query does full table scan."
```

### Example 3: Error Pattern
```
User: "We are seeing random errors - what's the pattern?"

Assistant: "Let me check error groupings."

[Uses MCP list_group_stats for last 6 hours]
[Uses gcloud to sample top error group, --limit=10]

"Error Pattern Analysis:

**Error**: ConnectionTimeout to external-api.example.com
**Frequency**: 42 occurrences in last 6 hours (7 per hour)
**Trend**: Increasing (was 2/hour yesterday)

**Time Pattern**: No specific pattern - distributed throughout the day

**Affected Resources**: Only cloud_run_job: data-sync

**Likely Cause**: External API experiencing degraded performance

**Recommended Actions**:
1. Add retry logic with exponential backoff
2. Contact external-api.example.com team about their performance
3. Consider adding circuit breaker pattern"
```

---

Remember: The goal is actionable insights with minimal token usage. Always prefer gcloud CLI for logs, use MCP only when gcloud cannot do it.
