---
name: discover
description: Invoke when the user runs /discover, or says "discover this project", "analyze the codebase", "what could we improve here", or similar. Also when entering a new project and asking what .claude setup improvements are possible.
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

## 2b. Assess MCP Server Opportunities

After scanning dependencies, check whether the project would benefit from live documentation via MCP servers. These are project-scoped additions — recommend them for the individual project, not the global Claude setup.

**Context7** (`npx -y @upstash/context7-mcp@latest`):
Pulls current, version-specific library docs into the context window at query time. Reduces hallucination risk for projects using actively-developed third-party libraries.

Recommend when:
- The project has 3+ non-trivial third-party library dependencies, **or**
- Dependencies include known fast-moving libraries (e.g., Next.js, React 18+, Prisma, Drizzle, tRPC, LangChain, Tailwind v4, Astro)

Note the detected libraries that triggered the recommendation — these will be listed in the report.

---

## 2c. Assess Third-Party Skill Packs

Check whether the project would benefit from third-party skill packs. These install alongside the framework and add domain-specific commands.

**Impeccable** (`npx skills add pbakaus/impeccable`):
Injects professional design vocabulary and UI polish commands (`/polish`, `/audit`, `/typeset`, `/overdrive`). Includes anti-pattern guidance for typography, color, layout, and motion.

Recommend when:
- The project has a frontend component (React, Vue, Svelte, Next.js, Astro, etc.), **and**
- UI quality or design polish is likely to matter (consumer-facing, design system, or portfolio work)

Do not recommend for purely backend, CLI, or infrastructure projects.

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

## Recommended MCP Servers
| Server | Purpose | Install | Detected Libraries |
|--------|---------|---------|-------------------|
| Context7 | Live library docs | `npx -y @upstash/context7-mcp@latest` | <list> |

_(Omit this section if no MCP servers were recommended.)_

## Recommended Skill Packs
| Pack | Purpose | Install | Trigger |
|------|---------|---------|---------|
| Impeccable | UI design vocabulary & polish commands | `npx skills add pbakaus/impeccable` | <detected frontend frameworks> |

_(Omit this section if no skill packs were recommended.)_

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
- Add recommended MCP servers to `.mcp.json` at the project root (Claude Code reads this automatically; do not place it inside `.claude/`)

Ask: "Want me to implement any of these quick wins now?"

If yes, implement the selected improvements immediately.
