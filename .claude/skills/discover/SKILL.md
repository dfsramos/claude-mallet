---
name: discover
description: Invoke when the user runs /discover, or says "discover this project", "analyze the codebase", "what could we improve here", or similar. Also when entering a new project and asking what .claude setup improvements are possible.
---
# Project Discovery

Analyse the project to identify opportunities for improving its `.claude/` framework setup.

---

## 1. Scan the Project

Identify stack and structure from manifests and entry points:
- Languages and frameworks (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.)
- Build tools, task runners, test frameworks
- Deployment configs, database tooling, migrations
- Overall layout and conventions

---

## 2. Detect External Services

Search imports and configs for third-party integrations:
- SDKs and API clients (Stripe, SendGrid, AWS, Twilio, etc.)
- Auth providers (Auth0, Firebase, OAuth)
- Data services (Redis, Elasticsearch, S3)
- Observability (Sentry, Datadog, LogRocket)

For each, note: service name, how it's used (SDK / HTTP / CLI), and where config lives (env vars, config files).

---

## 3. Assess Augmentation Opportunities

Check whether the project would benefit from project-scoped additions:

**MCP servers** — live docs, API access, or data-source integration. Recommend when dependencies include fast-moving libraries or the workflow would benefit from queryable external context. Example: Context7 (`npx -y @upstash/context7-mcp@latest`) for current, version-specific library docs.

**Skill packs** — domain-specific command bundles. Recommend when the project's domain matches an existing pack. Example: Impeccable (`npx skills add pbakaus/impeccable`) for frontend UI/design work.

Note the trigger (specific dependencies or project type) so the report can justify the recommendation.

---

## 4. Ask Focused Questions

As findings accumulate, use `AskUserQuestion` to resolve priorities:
- "Found [Service] SDK — research its API and create integration skills?"
- "Detected multiple deployment methods — which is primary?"
- "Found both [Tool A] and [Tool B] for [purpose] — preference?"

Ask about priorities, not everything. Provide context and clear options.

---

## 5. Research Confirmed Services

For services the user wants researched, use `WebSearch` to find official docs, common operations, auth requirements. Propose concrete skills (e.g., `stripe-refund`, `sendgrid-template-deploy`).

---

## 6. Identify Skill and Documentation Opportunities

Look for repeatable patterns worth capturing:

- **Skills** — deployment workflows, database operations, testing flows, scaffolding, release processes, environment management
- **Connection data** — DB hosts/ports, API base URLs, required env vars, dev/staging/prod distinctions
- **Project conventions** for `.claude/project/CLAUDE.md` — code organisation, naming, testing requirements, review processes
- **Promotable patterns** — generic workflows that could move to the base framework

For each skill candidate, note what it does, where it's currently implemented, and what could be automated.

---

## 7. Generate Report

Write the report to `.claude/project/discovery-YYYY-MM-DD.md`:

```markdown
# Project Discovery Report
Date: YYYY-MM-DD
Project: <name>

## Overview
<project type, stack, key findings>

## External Services
| Service | Purpose | Integration | Skill Opportunities |

## Recommended MCP Servers
| Server | Purpose | Install | Trigger |

_(Omit if none.)_

## Recommended Skill Packs
| Pack | Purpose | Install | Trigger |

_(Omit if none.)_

## Recommended Skills
**High Priority** / **Medium** / **Low** — name, description, why valuable.

## Connection Data
- Service/system → what to document, where it goes, required fields.

## Project Conventions (for .claude/project/CLAUDE.md)
- Area → convention.

## Promotable to Framework
- Pattern → why generic.

## Next Steps
1. Prioritised actions.
```

Present a summary to the user.

---

## 8. Offer Quick Wins

Offer to implement high-value, low-effort improvements immediately:
- Stub skill files for top 2–3 recommendations in `.claude/project/skills/`
- Connection data templates for critical services
- Project conventions written to `.claude/project/CLAUDE.md` (not base `CLAUDE.md`)
- MCP servers added to `.mcp.json` at project root (Claude Code reads this automatically; do not place inside `.claude/`)

Ask: "Want me to implement any of these now?" Implement whatever the user selects.
