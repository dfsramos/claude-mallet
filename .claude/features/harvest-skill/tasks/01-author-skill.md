# Task: 01-author-skill
Status: done
Deps: —

## Goal
Create .claude/project/skills/harvest/SKILL.md with a full workflow: pull check, framework drift detection, and skill promotion.

## Notes
- Skill is project-specific: lives in .claude/project/skills/harvest/, NOT in source/.claude/skills/
- Pull check: instruct Claude to verify ai-framework is up to date (git pull --ff-only) before proceeding
- Drift detection: compare every file in source/ against the corresponding file in target, report diffs, offer to copy updated files
- Skill promotion: scan target/.claude/project/skills/, let user select which to promote to source/.claude/skills/, handle conflicts intelligently
