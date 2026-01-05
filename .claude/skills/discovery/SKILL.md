# Data Engineering Discovery Skill

This skill enables Claude to conduct structured discovery sessions for data architecture and data engineering initiatives.

## Activation Keywords

Users can invoke this skill by saying:
- "Let's run a discovery on..."
- "Discovery session: [topic]"
- "Do discovery on..."
- "/discovery"

## Core Principles

### ALWAYS Use AskUserQuestion Tool
Using the AskUserQuestion tool is **NOT optional** during discovery. You must:
- Ask clarifying questions rather than making assumptions
- Build on previous answers to go deeper
- Present specific options with tradeoffs when appropriate
- Probe for hidden complexity and edge cases

### Discovery vs Implementation
Discovery is about understanding, not building. During discovery:
- DON'T propose specific implementations prematurely
- DO understand constraints, requirements, and tradeoffs
- DON'T make architectural decisions unilaterally
- DO surface options and their implications

### Question Quality
Good discovery questions are:
- **Specific**: "What's your daily data volume in GB?" not "How much data?"
- **Probing**: "What happens if the upstream API is down for 6 hours?"
- **Trade-off focused**: "Would you prefer lower latency or lower cost?"
- **Reality-checking**: "Who will maintain this pipeline in 6 months?"

## Three-Phase Discovery Process

### Phase 1: Data Landscape & Problem Space (2-4 rounds)

**Focus**: Understand the current state and the business problem.

**Key Questions to Explore**:

**Data Sources**:
- What data sources exist? (databases, APIs, files, streams, SaaS, third-party)
- What's the ownership model? (who owns the source systems?)
- Are schemas documented? Stable or frequently changing?
- What authentication/authorization is required?

**Data Characteristics**:
- What's the scale? Be specific:
  - Volume: Records/day? GB/day? Growth rate?
  - Velocity: Real-time, near-real-time, batch, mixed?
  - Variety: Structured, semi-structured, unstructured?
- What data quality issues exist today? (missing data, duplicates, stale data, format inconsistencies)

**Business Context**:
- What business questions need answering?
- Who are the stakeholders? (data analysts, data scientists, business users, external customers)
- What are the SLAs and latency requirements?
- What's the impact of data delays or errors?
- What's in scope vs explicitly out of scope?

**Example Round**:
```
Question 1: "What are the primary data sources for this pipeline?"
Options: [Postgres DB, REST APIs, S3 files, Kafka streams, Third-party SaaS]

Question 2: "What's your expected daily data volume?"
Options: [<1GB/day, 1-100GB/day, 100GB-1TB/day, >1TB/day]

Question 3: "What happens if data arrives 2 hours late?"
(This probes for SLA requirements and business impact)
```

### Phase 2: Technical Architecture & Pipeline Design (2-4 rounds)

**Focus**: Understand technical constraints and architectural options.

**Key Questions to Explore**:

**Target Architecture**:
- What's the target data platform? (BigQuery, Snowflake, Redshift, Databricks, custom)
- Data warehouse, data lake, lakehouse, or hybrid?
- What infrastructure? (GCP, AWS, Azure, on-prem)
- What's already built? What's greenfield?

**Processing Strategy**:
- Batch vs streaming vs micro-batch? Why?
- What transformation complexity? (simple mapping, complex joins, ML features, aggregations)
- What processing frameworks are already in use? (dbt, Spark, Beam, Dataflow, Airflow, Dagster)
- Any preferred languages or tools?

**Storage Strategy**:
- Partitioning strategy? (by date, by geography, by tenant)
- Clustering/sorting requirements?
- File formats? (Parquet, Avro, ORC, JSON)
- Compression preferences?
- Hot vs cold storage tiers?

**Integration & Dependencies**:
- What downstream consumers exist? (BI tools, ML models, other pipelines)
- What upstream dependencies? (other pipelines, manual processes)
- Any existing data contracts or SLAs?
- Change data capture (CDC) requirements?

**Cost & Performance**:
- Budget constraints?
- Query performance requirements?
- Storage cost vs compute cost priorities?
- Acceptable query latency?

**Observability**:
- How do you monitor data quality today?
- What metrics matter? (freshness, completeness, accuracy, latency)
- Alerting requirements and escalation paths?
- Logging and debugging needs?

**Example Round**:
```
Question 1: "What's your target data warehouse platform?"
Options: [BigQuery (GCP), Snowflake, Redshift (AWS), Databricks, Not decided yet]

Question 2: "What's more important for this use case?"
Options: [
  "Low latency (data available within minutes)",
  "Low cost (can tolerate daily batch)",
  "Balance between both"
]

Question 3: "What transformation tool do you prefer?"
Options: [dbt (SQL-based), Spark/PySpark (Python), Dataflow/Beam, No preference]
Description: Consider team skills and maintenance burden.
```

### Phase 3: Governance, Tradeoffs & Decisions (2-3 rounds)

**Focus**: Surface critical decisions, risks, and non-functional requirements.

**Key Questions to Explore**:

**Security & Governance**:
- PII or sensitive data? What regulations? (GDPR, HIPAA, SOC2, CCPA)
- Who needs access? Row-level or column-level security?
- Encryption requirements? (at rest, in transit)
- Audit logging requirements?
- Data classification and tagging?

**Architectural Tradeoffs**:
- Consistency vs availability? (CAP theorem for distributed systems)
- Normalization vs denormalization? (query performance vs storage)
- ELT vs ETL? (transform in warehouse vs before loading)
- Schema-on-write vs schema-on-read?
- Type 1 vs Type 2 slowly changing dimensions?

**Change Management**:
- Schema evolution strategy? (backward compatible, breaking changes allowed)
- Data versioning requirements?
- Blue/green deployments needed?
- Rollback strategy?

**Operational Concerns**:
- Disaster recovery requirements? (RPO/RTO)
- Data retention and archival policies?
- Backup strategy?
- Incident response plan?
- On-call rotation and support model?

**Future Considerations**:
- Expected growth over next 12 months?
- New data sources on the horizon?
- Potential new use cases?
- Technical debt concerns?
- Team skill gaps or training needs?

**Example Round**:
```
Question 1: "Does this pipeline handle PII or regulated data?"
Options: [
  "Yes, extensive PII (names, emails, SSN, etc.)",
  "Some PII (emails only)",
  "No PII or sensitive data"
]

Question 2: "What's your disaster recovery requirement?"
Options: [
  "Can re-run from source (acceptable data loss)",
  "Need point-in-time recovery (daily snapshots)",
  "Zero data loss tolerance (continuous backup)"
]

Question 3: "How do you want to handle schema changes from upstream sources?"
Options: [
  "Fail pipeline on schema change (strict validation)",
  "Auto-adapt to schema changes (schema-on-read)",
  "Manual approval process for schema changes"
]
```

## Building on Previous Answers

Each round should naturally flow from previous responses. Examples:

**If user says data volume is >1TB/day:**
- Ask about partitioning strategy
- Probe on cost optimization
- Question compute resource requirements

**If user mentions real-time requirements:**
- Ask about acceptable latency (seconds vs minutes)
- Probe on handling late-arriving data
- Question streaming technology preferences

**If user mentions complex transformations:**
- Ask about transformation logic ownership (analysts vs engineers)
- Probe on testing strategy for transforms
- Question whether logic should be reusable

**If user mentions PII:**
- Ask about specific compliance requirements
- Probe on data masking and anonymization
- Question access control and audit needs

## When to Go Deeper

Probe deeper when you detect:
- **Vague answers**: "A lot of data" → Ask for specific numbers
- **Hidden complexity**: "Just some joins" → Ask about cardinality and performance
- **Unstated assumptions**: "The API is reliable" → Ask about error handling
- **Risk areas**: "We'll figure that out later" → Surface the decision now
- **People problems**: "The team will handle it" → Clarify roles and skills

## Discovery Completion Criteria

A discovery session is complete when you can confidently answer:
1. What data goes in (sources, volumes, formats, quality)
2. What data comes out (targets, models, consumers)
3. How it gets there (processing approach, technology choices)
4. What could go wrong (failure modes, bottlenecks, risks)
5. How we know it's working (metrics, monitoring, alerts)
6. Who's responsible (owners, on-call, escalation)

Typically 10-15 rounds (30-60 total questions) are needed for thorough discovery.

## Deliverable: Data Architecture Specification

After discovery, synthesize findings into a comprehensive specification document.

### Specification Structure

#### 1. Executive Summary
- Business context and objectives (why we're building this)
- Key stakeholders and their needs
- Success criteria at a high level
- Timeline and phasing overview
- 3-5 sentences maximum

#### 2. Data Requirements

**Sources**:
- List each source with: type, volume, frequency, owner, stability, authentication
- Example: "Postgres DB (customer_db) - 50GB, 100K rows/day, stable schema, owned by Product team"

**Quality Expectations**:
- Completeness requirements (% of required fields)
- Freshness requirements (data available within X hours of source)
- Accuracy requirements (deduplication, validation rules)
- Known quality issues and mitigation plans

**Volume & Velocity**:
- Current and 12-month projected volumes
- Peak vs average load
- Growth assumptions

#### 3. Architectural Design

**Pattern**: Data warehouse | Data lake | Lakehouse | Kappa | Lambda | Other
**Justification**: Why this pattern? What alternatives were considered?

**Technology Stack**:
- Storage: [Platform, reasoning]
- Orchestration: [Tool, reasoning]
- Processing: [Framework, reasoning]
- Transformation: [Tool, reasoning]

**Architecture Diagram** (describe key components and data flows):
```
[Source Systems] → [Ingestion Layer] → [Raw Storage] →
[Transformation Layer] → [Curated Storage] → [Consumption Layer]
```

#### 4. Pipeline Architecture

**Ingestion Strategy**:
- Full refresh vs incremental? (per source)
- CDC approach if applicable
- Error handling and retry logic
- Schema validation approach

**Transformation Strategy**:
- ELT or ETL? Why?
- Staging approach (bronze/silver/gold or other)
- Transformation orchestration
- Testing strategy for transformations

**Loading Strategy**:
- Insert/update pattern (append, merge, overwrite)
- Partitioning and clustering
- Deduplication approach
- Idempotency guarantees

#### 5. Transformation Logic

**Key Business Rules**:
- Document critical transformations
- Data lineage for key metrics
- Join strategies and grain

**Data Models**:
- Dimensional model? Normalized? Denormalized?
- Fact and dimension tables
- Slowly changing dimension strategy
- Surrogate key strategy

**Example**:
```
daily_revenue (fact table)
- Primary grain: One row per order
- SCD Type: Type 2 for customer dimensions
- Partitioned by: order_date
- Updated: Daily at 2 AM UTC
```

#### 6. Storage Strategy

**Partitioning**:
- Partition keys and reasoning
- Expected partition size
- Retention per partition

**Optimization**:
- Clustering/sorting keys
- Compression strategy
- File size targets
- Materialized views or aggregation tables

**Formats & Compression**:
- File format choice (Parquet, Avro, etc.) and why
- Compression algorithm and rationale

#### 7. Security & Governance

**Access Control**:
- Who has access to what? (by role)
- Row-level security requirements
- Column-level masking for PII

**Compliance**:
- Specific regulations (GDPR, HIPAA, etc.)
- Data retention and deletion policies
- Audit logging requirements
- Data classification and tagging

**Encryption**:
- At-rest encryption approach
- In-transit encryption requirements
- Key management strategy

#### 8. Operational Concerns

**Monitoring & Alerting**:
- Key metrics to track (freshness, volume, quality, latency, cost)
- Alert thresholds and escalation
- Dashboard requirements
- Logging strategy

**SLAs & Support**:
- Pipeline SLAs (by consumer)
- Incident response process
- On-call rotation
- Documentation requirements

**Cost Management**:
- Budget and cost allocation
- Cost monitoring and alerts
- Optimization strategies

**Disaster Recovery**:
- Backup strategy
- RPO (Recovery Point Objective)
- RTO (Recovery Time Objective)
- Failover procedures

#### 9. Implementation Phases

Break into phases with:
- **Phase name and goal**
- **Deliverables** (what gets built)
- **Dependencies** (what must be complete first)
- **Validation** (how we know it works)
- **Rollout strategy** (how we deploy)

**Example**:
```
Phase 1: Foundation (Weeks 1-2)
- Set up infrastructure (GCS buckets, BigQuery datasets, service accounts)
- Implement ingestion for Source A (Postgres)
- Basic monitoring and alerting
- Dependency: GCP project provisioned
- Validation: Data lands in raw zone daily

Phase 2: Core Transformations (Weeks 3-4)
- Build bronze → silver transformations in dbt
- Implement data quality tests
- Add lineage tracking
- Dependency: Phase 1 complete, dbt environment ready
- Validation: Silver tables match business logic, tests pass
```

#### 10. Architectural Decision Records

For each major decision, document:
- **Decision**: What was decided
- **Context**: What problem we were solving
- **Options Considered**: What alternatives we evaluated
- **Rationale**: Why we chose this option
- **Tradeoffs**: What we're giving up
- **Consequences**: What this means going forward

**Example**:
```
ADR-001: Use ELT with dbt instead of ETL with Dataflow

Context: Need to transform raw data into analytical models

Options Considered:
1. ETL with Dataflow + Python
2. ELT with dbt + SQL
3. ETL with Spark on Dataproc

Decision: ELT with dbt

Rationale:
- Team has strong SQL skills, limited Python/Spark experience
- BigQuery compute is cost-effective for our volume
- dbt provides built-in testing and documentation
- Faster iteration for analysts

Tradeoffs:
- Giving up: Fine-grained control over processing, complex Python logic
- Gaining: Analyst autonomy, faster development, better documentation

Consequences:
- All transformations must be expressible in SQL
- Need to train team on dbt best practices
- Complex logic may require staging CTEs or views
```

#### 11. Success Metrics

Define how success is measured:

**Data Quality**:
- Freshness: Data available within X hours of source update
- Completeness: >Y% of records have all required fields
- Accuracy: <Z% error rate on validation rules

**Performance**:
- Query latency: P95 < X seconds for standard queries
- Pipeline runtime: Complete within X hours
- Scalability: Handle 2x volume without degradation

**Cost**:
- Storage cost: $X/month target
- Compute cost: $Y/month target
- Cost per GB processed: $Z

**Operational**:
- Uptime: >99.X% pipeline success rate
- MTTR: Mean time to recovery < X hours
- Incident rate: <Y incidents per month

#### 12. Open Questions & Risks

**Be honest about**:
- What you don't know yet
- Where assumptions could be wrong
- What could cause the project to fail
- What dependencies are uncertain
- What technical spikes are needed

**Example**:
```
Open Questions:
- Q: Will the upstream API rate limit cause issues at scale?
  Action: Load test with 2x expected volume
  Owner: [Name]
  By: [Date]

- Q: Can BigQuery handle our join complexity at this scale?
  Action: Prototype with realistic data sample
  Owner: [Name]
  By: [Date]

Risks:
- Risk: Source schema changes without notice (High probability, High impact)
  Mitigation: Implement schema validation and alerting in ingestion

- Risk: Team lacks dbt experience (Medium probability, Medium impact)
  Mitigation: Training sessions and pair programming for first 2 weeks
```

## Writing Quality Standards

The specification must be:
- **Specific**: Use numbers, names, and concrete details
- **Actionable**: Engineers can start building from this
- **Honest**: Surface risks and unknowns openly
- **Justified**: Explain why, not just what
- **Traceable**: Link decisions back to requirements

**Bad Example**: "We'll use a scalable architecture with good performance."
**Good Example**: "We'll use BigQuery with date-partitioned tables (daily partitions) and clustering on user_id. This supports our requirement for <5 second query response times on user-level aggregations while keeping storage costs under $500/month for our projected 100GB/day volume."

## Anti-Patterns to Avoid

**Don't**:
- Assume you know what the user needs
- Rush through discovery to start building
- Ask generic questions without context
- Accept vague answers ("it depends", "some", "a lot")
- Make technology choices without understanding requirements
- Ignore operational concerns until later
- Over-engineer for hypothetical future requirements
- Under-estimate complexity to look good

**Do**:
- Ask dumb questions if something is unclear
- Probe on edge cases and failure modes
- Surface tradeoffs explicitly
- Check your understanding by summarizing back
- Admit when you don't have enough information
- Push back on unrealistic requirements
- Highlight where user input is critical

## Example Discovery Flow

```
Round 1:
Q: "What's the primary data source for this pipeline?"
A: "Our Postgres production database"

Round 2 (build on previous):
Q: "How large is this Postgres database and how fast is it growing?"
A: "Currently 500GB, growing about 50GB/month"

Q: "Do you need all tables or a subset?"
A: "Just 5 tables related to orders and customers"

Round 3 (go deeper):
Q: "What's the update pattern on these tables - mostly inserts or lots of updates/deletes?"
A: "Orders are insert-only, customers get updated frequently"

Q: "How will you identify changed customer records?"
Options: [CDC with debezium, updated_at timestamp, Full table refresh daily]

[Continue building understanding across all phases...]

Round 12 (validate understanding):
"Let me confirm my understanding:
- 5 tables from Postgres, currently 50GB relevant data
- Orders: append-only, 10K/day, need within 1 hour
- Customers: updates frequently, ~100K updates/day, need within 1 hour
- Target: BigQuery with dbt transformations
- Output: Daily revenue reports and customer segmentation
- SLA: Data available by 8 AM for business users
- Budget: ~$1000/month
- Team: 2 data engineers, 3 analysts (SQL-strong)

Is this accurate? What did I miss?"
```

---

## Summary

This discovery skill helps you thoroughly understand data engineering requirements before jumping to implementation. Use it to:
- Ask the right questions in a structured way
- Surface critical decisions and tradeoffs early
- Build shared understanding with stakeholders
- Create actionable specifications that lead to successful implementations

Remember: **Discovery is not wasted time**. It's the foundation that prevents costly rework later.
