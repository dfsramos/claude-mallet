---
description: "The write-task skill fires on a natural request and produces its skeleton with evidence and checkable completion conditions."
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Create a Jira ticket description for this: the nightly export job writes CSV files with Windows line endings, and the downstream importer on the Linux box rejects them. I found it yesterday morning when the import failed on 3 of the 12 files. Just give me the ticket text, I'll paste it in myself.
