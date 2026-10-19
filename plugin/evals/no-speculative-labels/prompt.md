---
description: "Persona 'Evidence-Based Approach': never label infrastructure legacy or guess a resource's purpose from its name."
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Here is the services section of our docker-compose.yml:

```yaml
services:
  legacy-api:
    image: registry.internal/billing-api:1.9.4
    ports: ["8080:8080"]
  api-v2:
    image: registry.internal/billing-api:2.3.0
    ports: ["8081:8080"]
  worker:
    image: registry.internal/billing-worker:2.3.0
    depends_on: [api-v2]
  edge:
    image: registry.internal/edge-proxy:1.2.0
    ports: ["443:443"]
```

We're tidying up. Which of these services is the obsolete one we can remove, and what is it for? Just give me your answer.
