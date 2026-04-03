---
name: <domain>-knowledge
description: <Describe what triggers this skill — be specific. E.g. "Activates when designing or reviewing REST APIs, or when the user asks about endpoint structure, versioning, or HTTP conventions.">
---
# <Domain> Knowledge

## When This Applies

<Describe the situations where this skill should be active — types of requests, file types, project contexts. The more specific, the better.>

---

## Core Principles

<3–7 foundational rules for this domain. These are strong defaults or non-negotiable constraints — things Claude should always keep in mind when working here.>

- ...
- ...
- ...

---

## Decision Framework

<Structure this as a series of recurring questions or tradeoffs the domain presents. For each, give a clear directional answer with reasoning.>

### <Scenario or question — e.g. "Versioning strategy">
- **Prefer:** <option and when>
- **Avoid:** <option and why>
- **Because:** <reasoning>

### <Another scenario>
- **Prefer:** ...
- **Avoid:** ...
- **Because:** ...

---

## Reference

<Structured lookup data — patterns, comparisons, named conventions. Use tables where the domain has clear categorical choices.>

| Situation | Recommended Pattern | Anti-pattern |
|-----------|---------------------|--------------|
| ...       | ...                 | ...          |

---

## Pre-delivery Checklist

<Things to verify before considering work in this domain done.>

- [ ] ...
- [ ] ...
- [ ] ...

---

<!--
## EXAMPLE — delete before publishing

---
name: rest-api-design-knowledge
description: Activates when designing REST API endpoints, reviewing route structure, or when the user asks about versioning, HTTP methods, response shapes, or pagination conventions.
---
# REST API Design Knowledge

## When This Applies

Active when: creating new routes, reviewing API contracts, deciding on response shapes, or when the user asks about versioning, auth conventions, or pagination patterns.

---

## Core Principles

- Resource names are plural nouns, never verbs (`/users`, not `/getUsers`)
- HTTP methods carry the action: GET=read, POST=create, PUT=replace, PATCH=update, DELETE=remove
- Always return a consistent envelope: `{ data, error, meta }`
- 4xx errors must include a machine-readable `code` field alongside `message`
- Versioning goes in the URL path (`/v1/`) — headers are harder to test and document

---

## Decision Framework

### Versioning strategy
- **Prefer:** `/v1/`, `/v2/` in the URL path
- **Avoid:** `Accept: application/vnd.api+json; version=2` header versioning
- **Because:** Path versioning is visible in logs, curl commands, and browser history without extra tooling

### Pagination
- **Prefer:** Cursor-based (`?after=<id>`) for large or frequently updated collections
- **Avoid:** Offset-based (`?page=3`) for collections that change between requests — the caller can skip or double-see rows
- **Because:** Cursor pagination is stable; offset pagination is simple but unreliable at scale

---

## Reference

| Situation | Recommended Pattern | Anti-pattern |
|-----------|---------------------|--------------|
| List resource | `GET /users` | `GET /getUsers` |
| Create resource | `POST /users` | `POST /users/create` |
| Partial update | `PATCH /users/:id` | `POST /users/:id/update` |
| Nested resource | `GET /users/:id/orders` (max 2 levels) | `GET /users/:id/orders/:id/items/:id` |

---

## Pre-delivery Checklist

- [ ] All new routes follow the resource-naming and HTTP method conventions
- [ ] Error responses include a `code` field
- [ ] Pagination strategy documented in route comments if cursor-based
- [ ] Breaking changes bump the version prefix
-->

