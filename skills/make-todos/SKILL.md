---
name: make-todos
description: Creates a structured task list for the current work and works through it in order. Use when invoked via /make-todos, when the work has multiple steps where later steps depend on earlier ones completing first, or when scope is uncertain and the plan should be visible before starting. Not for single-step, conversational, or obviously linear tasks.
---

# Make Todos

Read the project's agent instructions (e.g. AGENTS.md), including any nested AGENTS.md in directories you will touch, before applying this skill.

## When not to use

Do **not** create a task list for:
- Single-step tasks or trivial changes
- Conversational requests (questions, explanations)
- Work where the steps are obvious and linear (e.g. "rename this variable across the codebase")

## Procedure

1. **Decompose the work** into focused, completable units using the granularity guidance below.
2. **Create the task list** using whatever tracking mechanism is available: a task-tracking tool (TodoWrite, TaskCreate), YAML frontmatter in plan mode, or a numbered checklist in your response.
3. **Start immediately** -- mark the first item in-progress and begin working on it in the same response. Do not pause to announce the plan.
4. **Complete sequentially** -- mark each item done as you finish it, then start the next. Only one item should be in-progress at a time.

## Granularity

Each item should be independently verifiable -- you can tell whether it is done without checking other items.

**Too coarse (bad):**
- "Implement the new feature" -- covers definition, handler, registration, tests, docs

**Too fine (bad):**
- "Add import statement for uuid package" -- trivial, automatic side-effect

**Right level (good):**
- "Add the config option and read it at startup"
- "Implement handler following existing patterns"
- "Add tests using existing test fixtures"
- "Run build/test/lint and fix failures"
- "Update project documentation"

## Task naming

Name each item as an action: "Add X", "Update Y", "Fix Z", "Extract W" -- not nouns like "Error handling" or "Tests".

## Mid-flight adjustments

- **Blocked:** If an item cannot proceed due to an unexpected dependency, mark it pending, note the blocker, and either create a new prerequisite item or ask the user.
- **Failed:** If an item's implementation does not work (e.g. tests fail), keep it in-progress and debug. Do not mark it done. Split into diagnostic sub-items if the problem is complex.
- **Discovered work:** When implementation reveals necessary work not in the original list, add new items in dependency order. Do not silently expand an existing item's scope.
- **Scope change:** If the user changes direction, regenerate the list rather than patching a stale one.

## Anti-patterns

- Do not create items for work that will happen automatically as a side-effect of another item.
- Do not front-load the entire list if scope is unclear. Create items for what is known and add more as the work unfolds.
- Do not pause after creating the list to ask for approval -- start working immediately unless the user asked to review the plan first.

## Related skills

- If scope is unclear, consider `/ask-questions` first to clarify requirements before decomposing.
- Include a final item for `/verify-changes` to run the project's build/test/lint workflow.
- After all items are complete, use `/commit-message` to generate a commit message.
