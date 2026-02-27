# Feature: harvest-skill
Status: done
Created: 2026-02-27
Branch: f/harvest-skill

## Goal
Replace harvest.sh with a project-specific Claude skill that performs intelligent framework drift detection and skill promotion.

## Context
The current harvest.sh script copies project-specific skills from a target project into source/.claude/skills/ and removes them from the project. It has no awareness of whether the framework's base files (CLAUDE.md, settings.json, hooks, base skills) have drifted from what's installed in the target. The new skill runs entirely within Claude, enabling semantic comparison, context-aware conflict resolution, and a pull-first workflow to ensure the framework is up to date before harvesting.

## Tasks
- [x] 01-author-skill — Create .claude/project/skills/harvest/SKILL.md [deps: —] [parallel: no]
- [x] 02-remove-script — Delete harvest.sh [deps: 01] [parallel: no]
