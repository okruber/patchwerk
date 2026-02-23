<!-- ROUTING FILE: Load skills as directed. Read before writing code. -->

# Agent Configuration

## Project Overview

**Purpose**: Demonstration of agentic coding best practices using skill-based routing architecture. Collection of reusable configuration patterns for multi-project management.

**Tech Stack**:
- Language: Python
- Package Management: `uv` (preferred over `pip`)
- Testing: pytest via `devrun` agent
- Infrastructure: Google Cloud Platform (Cloud Run, Cloud Functions)
- VCS: Git (feature branches, never push unless asked)

**Architecture**: Skills provide domain-specific guidance (Python standards, testing patterns, debugging, GCP operations). AGENTS.md routes to appropriate skills based on context.

---

@.agent-skills/framework/core.md
