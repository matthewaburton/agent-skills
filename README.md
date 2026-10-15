# Agent Skills

Reusable, project-agnostic [skills for AI agents](https://agentskills.io/)
(Claude Code, Cursor, Codex, etc.). Each skill defines a structured procedure
that agents follow when invoked -- no project-specific references, so they work
across any codebase as a starting point you customize per project.

## Available skills

| Skill              | Purpose                                                                                                    |
|--------------------|------------------------------------------------------------------------------------------------------------|
| `ask-questions`    | Gather structured requirements through targeted questions with discrete options before starting work       |
| `commit-message`   | Generate Beams-style commit messages with imperative subjects, what-and-why bodies, and ASCII-only output  |
| `explore-codebase` | Systematically read existing patterns, helpers, and conventions before implementing changes                |
| `make-todos`       | Decompose work into a tracked task list with proper granularity and sequencing                             |
| `review-plan`      | Verify an implementation plan for accuracy, correctness, clarity, and completeness before executing it     |
| `verify-changes`   | Run the full build/test/lint workflow, check the changed behavior, and update affected documentation       |

## Deploying skills to a project

Copy the skill directory into `.agents/skills/` in the target project:

```
cp -r skills/<skill-name> <target-project>/.agents/skills/
```

Target projects are expected to have `.claude/skills/` and `.cursor/skills/` as
symlinks pointing to `../.agents/skills/`, so no further wiring is needed after
the copy.

> [!TIP]
> Be sure to check out [Agent Skills > Quickstart](https://agentskills.io/skill-creation/quickstart)

## Customizing copies

Skills here are starting points, not packages to keep in sync. Once copied into
a project, a skill belongs to that project: customize it freely with the
project's commands, conventions, and checks. Copies are expected to diverge
from the generic versions.

Every so often, run `/harvest-skill-updates` from this repository. It finds the
project copies, shows what each project changed, and helps fold improvements
that would help every project back into the generic versions here. Nobody needs
to record which version a copy came from; the harvest infers it from this
repository's history.

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

- `name`: Slug used to invoke the skill (e.g. `commit-message`); must match the
  directory name
- `description`: Summary the agent harness uses to decide when to apply the
  skill; include the slash command, trigger phrases, and key exclusions here

## Writing new skills

Skills must contain no customer-specific or project-specific content -- no
customer, engagement, or project names, file paths, tool names, or domain
terminology tied to a particular codebase. This includes examples: write new
generic examples rather than adapting ones from a real project. When an idea
comes from a project's copy of a skill, rewrite it from scratch rather than
editing the project's text down. Skills should generalize across tech stacks.

The `description` frontmatter field is critical: agents see only `name` and
`description` when deciding whether a skill applies, and read the body only
after the skill is invoked. Include the slash command, natural-language trigger
phrases, and any important exclusions ("Not for ...").

Each skill should document:
- When not to use it, if there are real exclusions worth spelling out
- A concrete procedure
- Anti-patterns to avoid
- Related skills to chain into

Write constraints as instructions ("Never ...", "Run ..."), not preferences
("Consider ...", "It is usually better to ..."). Soft phrasing reads as
optional. Keep skill files ASCII-only.

## Maintaining this repository

- `make lint` checks each skill's frontmatter, that its `name` matches its
  directory and its description mentions its slash command, that skill files
  are ASCII-only, that the skills tables in README.md and AGENTS.md match
  `skills/` and each other, and that the sections the two files share are
  identical. Run it before committing.
- `harvest-skill-updates` (under `.agents/skills/`) is a maintenance skill for
  this repository only. It is not listed in the skills table and is not meant to
  be copied into projects.

## License

[Unlicense](LICENSE) (Public Domain)
