---
name: discover
description: Invoke when the user runs /discover, or says "discover this project", "analyze the codebase", "what could we improve here", or similar. Also when entering a new project and asking what Claude Code setup improvements are possible.
---
# Project Discovery

Analyse the project to identify opportunities for improving its Claude Code setup: project skills, MCP servers, conventions, and settings.

---

## 1. Scan the Project

Identify stack and structure from manifests and entry points:
- Languages and frameworks (`package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.)
- Build tools, task runners, test frameworks
- Deployment configs, database tooling, migrations
- Overall layout and conventions

---

## 1.5. Surface Critical Files

Identify the files that the most of the codebase depends on — the highest-centrality modules a new contributor (or AI agent) must understand first.

Use the "Think in Code" principle: write a short script to count inbound references rather than reading files manually. Adapt the script to the primary language detected in Step 1.

**JS / TS:**
```bash
find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  ! -path "*/node_modules/*" ! -path "*/dist/*" ! -path "*/.next/*" \
  | xargs grep -h "from ['\"]" 2>/dev/null \
  | sed -nE "s/.*from ['\"]([./][^'\"]*)['\"].*/\1/p" \
  | sed 's/\/index$//' | sort | uniq -c | sort -rn | head -10
```

**Python:**
```bash
find . -name "*.py" ! -path "*/__pycache__/*" ! -path "*/venv/*" \
  | xargs grep -hE "^from \.|^import \." 2>/dev/null \
  | sed -nE 's/^(from|import)[[:space:]]+([^[:space:]]+).*/\2/p' \
  | sort | uniq -c | sort -rn | head -10
```

**Go / Rust / other languages:** write an equivalent that extracts local import paths and counts frequency.

Report files with noticeably more references than the median (typically 3× or more). Also flag any file in a path containing `lib/`, `utils/`, `shared/`, `core/`, or `common/` that appears in the top results — these are structurally load-bearing regardless of reference count.

Skip this step for projects with fewer than ~15 source files — the answer will be obvious from a directory listing.

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

Check whether the project would benefit from project-scoped additions.

Read `${CLAUDE_SKILL_DIR}/catalog.md`. It lists the MCP servers, skill packs, and code intelligence plugins this skill can recommend, each with its install command and the signals that justify or rule it out. Evaluate every entry against what steps 1 and 2 found.

Beyond the catalog, still consider an MCP server for any external service from step 2 the workflow would benefit from querying directly (live docs, API access, data-source integration), and any skill pack whose domain matches the project's.

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
- **Project conventions** for `.mallet/conventions.md` — code organisation, naming, testing requirements, review processes
- **Promotable patterns** — generic workflows that could move to the base framework

For each skill candidate, note what it does, where it's currently implemented, and what could be automated.

---

## 7. Generate Report

Write the report to `.mallet/discovery-YYYY-MM-DD.md`:

```markdown
# Project Discovery Report
Date: YYYY-MM-DD
Project: <name>

## Overview
<project type, stack, key findings>

## Critical Files
| File | Inbound refs | Why it matters |

_(Omit if fewer than ~15 source files or no clear outliers.)_

## External Services
| Service | Purpose | Integration | Skill Opportunities |

## Recommended MCP Servers
| Server | Purpose | Install | Trigger |

_(Omit if none.)_

## Recommended Skill Packs
| Pack | Purpose | Install | Trigger |

_(Omit if none.)_

## CLI-Anything Harnesses
| Harness | Software | Install |
_(List only harnesses relevant to detected software. Omit section if none detected.)_

## Code Intelligence Plugins
| Language | Plugin | Binary | Binary on PATH? |

_(Omit if every detected language's plugin is already installed or none has one.)_

## Recommended Skills
**High Priority** / **Medium** / **Low** — name, description, why valuable.

## Connection Data
- Service/system → what to document, where it goes, required fields.

## Project Conventions (for .mallet/conventions.md)
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
- Stub skill files for top 2–3 recommendations in `.mallet/skills/`
- Connection data templates for critical services
- Project conventions written to `.mallet/conventions.md` (not base `CLAUDE.md`)
- MCP servers added to `.mcp.json` at project root (Claude Code reads this automatically; do not place inside `.claude/`)
- Code intelligence plugins whose binary is already on `PATH`, installed with `claude plugin install` — ask whether to use user or project scope

Ask: "Want me to implement any of these now?" Implement whatever the user selects.
