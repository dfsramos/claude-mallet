---
name: discover
description: Performs structured project discovery to identify improvement opportunities for the .claude/ setup. Invokes when the user runs /discover or uses conversational phrases like "discover this project", "analyze the codebase", or "what could we improve here". Scans for external services, common patterns, and generates actionable recommendations.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, AskUserQuestion
---
# Project Discovery

Perform a comprehensive analysis of the project to identify opportunities for improving the `.claude/` framework setup.

---

## 1. Initial Scan

Scan the project structure to understand:
- Primary languages and frameworks (check package.json, requirements.txt, go.mod, Cargo.toml, etc.)
- Build tools and task runners (Makefile, package.json scripts, etc.)
- Testing frameworks and patterns
- Deployment configurations
- Database tools and migrations
- Project structure and organization

Be thorough but focused — look at configuration files, main directories, and entry points.

---

## 2. Detect External Services

Search for external service integrations by looking for:
- API client libraries and SDKs (imports, dependencies, package.json)
- Third-party service references (Stripe, SendGrid, AWS, Twilio, etc.)
- Authentication providers (Auth0, Firebase, OAuth configs)
- Data services (Redis, Elasticsearch, S3, etc.)
- Monitoring/logging services (Sentry, Datadog, LogRocket, etc.)

For each significant external service found, note:
- Service name and purpose
- How it's being used (client library, direct HTTP calls, CLI)
- Configuration locations (env vars, config files)

---

## 3. Interactive Questions

As you discover significant findings, ask the user for guidance using AskUserQuestion:

**When to ask:**
- External service detected: "Found [Service] SDK — should I research their API and create integration skills?"
- Multiple patterns found: "Detected multiple deployment methods — which is the primary one?"
- Ambiguous tooling: "Found both [Tool A] and [Tool B] for [purpose] — which do you prefer for operations?"
- Large scope detected: "Found extensive [area] patterns — should I deep-dive into this area?"

**Keep questions focused:**
- Ask about priorities, not everything at once
- Provide context about what you found
- Offer clear options with recommendations when appropriate

---

## 4. Research External Services

For each external service the user confirms should be researched:
- Use WebSearch to find official documentation
- Identify common operations and API patterns
- Note authentication requirements and configuration
- Propose specific skills that would be useful (e.g., "stripe-refund", "sendgrid-template-deploy")

Keep research focused on practical operations that would benefit from automation.

---

## 5. Identify Skill Opportunities

Look for repeatable patterns that could become skills:

**Common patterns to look for:**
- Deployment workflows (deploy to staging, deploy to prod, rollback)
- Database operations (migrations, seeding, backup/restore)
- Testing flows (run specific test suites, integration tests, e2e)
- Code generation (scaffolding, boilerplate creation)
- Build and release processes
- Environment management
- Data transformations or imports

For each pattern, note:
- What the operation does
- Where it's currently implemented (scripts, commands, manual steps)
- How frequently it's likely needed
- What could be automated

---

## 6. Identify Connection Data

Document services and systems that should have connection data templates:

- Database connection details (host, port, database name patterns)
- API endpoints (base URLs, versioning, authentication)
- External service credentials structure (what env vars are needed)
- Development vs staging vs production distinctions

---

## 7. Identify Project Conventions

Look for project-specific patterns worth documenting in `.claude/project/CLAUDE.md` (not the base `CLAUDE.md`):

- Code organization patterns (where do new features go?)
- Naming conventions (files, functions, branches, commits)
- Testing requirements (coverage thresholds, required test types)
- Review processes (PR templates, required checks)
- Environment setup (required tools, configuration steps)

---

## 8. Identify Promotable Patterns

Note generic patterns that could benefit other projects:

- Framework-agnostic workflows
- Common service integrations
- Reusable skill templates
- General best practices discovered

These are candidates for promoting to the base framework rather than keeping project-specific.

---

## 9. Generate Report

Create a comprehensive report at `.claude/discovery-YYYY-MM-DD.md` with:

```markdown
# Project Discovery Report
Date: YYYY-MM-DD
Project: <project-name>

## Overview
<brief summary of project type, stack, and key findings>

## External Services Detected
| Service | Purpose | Integration Type | Skill Opportunities |
|---------|---------|------------------|---------------------|
| ... | ... | ... | ... |

## Recommended Skills
### High Priority
- **[skill-name]**: <description> — <why it's valuable>

### Medium Priority
- ...

### Low Priority (Future Consideration)
- ...

## Connection Data to Document
- **[Service/System]**: <what should be documented>
  - Location: <where config should go>
  - Required fields: <what needs to be captured>

## Project Conventions for .claude/project/CLAUDE.md
- **[Area]**: <convention to document>

## Promotable to Framework
- **[Pattern/Skill]**: <description> — <why it's generic enough>

## Next Steps
1. <prioritized action>
2. <prioritized action>
3. ...
```

Save the report and present a summary to the user.

---

## 10. Offer Quick Wins

Based on the findings, offer to immediately implement high-value, low-effort improvements:

- Create stub skill files for top 2-3 recommended skills in `.claude/project/skills/`
- Add connection data templates for critical services
- Write project conventions to `.claude/project/CLAUDE.md` (not the base `CLAUDE.md`)

Ask: "Want me to implement any of these quick wins now?"

If yes, implement the selected improvements immediately.
