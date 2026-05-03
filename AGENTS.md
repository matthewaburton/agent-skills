# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Purpose

This is the source-of-truth repository for reusable AI agent skills. Skills are designed to be project-agnostic and are copied into target projects as needed.

## Skill structure

Each skill is a directory under `skills/` containing a `SKILL.md`  file with YAML frontmatter, as well as any optional resource files:

```
skills/
  <skill-name>/
    SKILL.md        -- YAML frontmatter (name, description) + skill body
    <...>           -- Optional resource files
```

The frontmatter fields:

- `name` -- slug used to invoke the skill (e.g. `commit-message`)
- `description` -- one-sentence summary used by the agent harness to match invocations; include trigger phrases here

## Deploying skills to a target project

Copy the skill directory into `.agents/skills/` in the target project:

```
cp -r skills/<skill-name> <target-project>/.agents/skills/
```

Target projects are expected to have `.claude/skills/` and `.cursor/skills/` as symlinks pointing to `../.agents/skills/`, so no further wiring is needed after the copy.

## Writing new skills

Skills must contain no project-specific references -- no project names, file paths, tool names, or domain terminology tied to a particular codebase. Skills should generalize across tech stacks. Where examples are needed, use generic illustrative ones rather than names from any real project.

The `description` frontmatter field is critical: the agent harness uses it to match user intent to the correct skill. Include both the slash command name and natural-language trigger phrases.

Each skill should document:
- When to apply (and when not to)
- A concrete procedure
- Anti-patterns to avoid
- Related skills to chain into

## Available skills

| Skill | Purpose |
|---|---|
| `ask-questions` | Gather structured requirements before starting work |
| `commit-message` | Generate Git commit messages from diffs |
| `explore-codebase` | Systematic reconnaissance before implementation |
| `make-todos` | Decompose work into a tracked task list |
| `review-plan` | Verify a plan for accuracy and completeness before implementing |
| `verify-changes` | Run build/test/lint and check whether docs need updating |
