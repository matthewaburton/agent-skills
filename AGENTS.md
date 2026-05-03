# AGENTS.md

This file provides guidance to AI agents when working with code in this
repository.

**Sync requirement:** README.md and this file share overlapping content
(purpose, skill structure, deployment, authoring guidelines, and the available
skills table). When updating one, check whether the change applies to the other
and keep them consistent.

## Purpose

This is the source-of-truth repository for reusable AI agent skills. Skills are
designed to be project-agnostic and are copied into target projects as needed.

## Skill structure

Each skill is a directory under `skills/` containing a `SKILL.md` file with YAML
frontmatter, plus optional resource files:

```
my-skill/
├── SKILL.md          # Required: YAML frontmatter + skill body
├── scripts/          # Optional: Executable code
├── references/       # Optional: Documentation
├── assets/           # Optional: Templates, resources, etc.
└── ...               # Optional: Additional files or directories
```

The frontmatter fields:

- `name`: Slug used to invoke the skill (e.g. `commit-message`)
- `description`: One-sentence summary used by the agent harness to match
  invocations; include trigger phrases here

## Deploying skills to a target project

Copy the skill directory into `.agents/skills/` in the target project:

```
cp -r skills/<skill-name> <target-project>/.agents/skills/
```

Target projects are expected to have `.claude/skills/` and `.cursor/skills/` as
symlinks pointing to `../.agents/skills/`, so no further wiring is needed after
the copy.

## Writing new skills

Skills must contain no project-specific references -- no project names, file
paths, tool names, or domain terminology tied to a particular codebase. Skills
should generalize across tech stacks. Where examples are needed, use generic
illustrative ones rather than names from any real project.

The `description` frontmatter field is critical: the agent harness uses it to
match user intent to the correct skill. Include both the slash command name and
natural-language trigger phrases.

Each skill should document:
- When to apply (and when not to)
- A concrete procedure
- Anti-patterns to avoid
- Related skills to chain into

## Available skills

| Skill              | Purpose                                                                                                    |
|--------------------|------------------------------------------------------------------------------------------------------------|
| `ask-questions`    | Gather structured requirements through targeted questions with discrete options before starting work       |
| `commit-message`   | Generate Git commit messages from diffs using imperative subjects, scannable bodies, and ASCII-only output |
| `explore-codebase` | Systematically read existing patterns, helpers, and conventions before implementing changes                |
| `make-todos`       | Decompose work into a tracked task list with proper granularity and sequencing                             |
| `review-plan`      | Verify an implementation plan for accuracy, correctness, and clarity before executing it                   |
| `verify-changes`   | Run the project's build/test/lint workflow and check whether documentation needs updating                  |
