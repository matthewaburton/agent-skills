---
name: harvest-skill-updates
description: Reviews per-project copies of this repository's skills for general-purpose improvements worth folding back into the generic versions, and lists skills that exist only in projects as new-skill candidates. Use when invoked via /harvest-skill-updates, or when the user asks to "harvest skill updates", "check the project copies of the skills", or "see how the skills changed elsewhere". Only for maintaining this skills repository; not deployed to other projects.
---

# Harvest Skill Updates

Read this repository's AGENTS.md before applying this skill.

Skills in `skills/` are starting points. Projects copy them and customize them freely, so copies are expected to differ from the generic versions. The goal here is to **harvest** ideas that would help every project, not to bring copies back in line. Never edit a project's copy.

## The rule that overrides everything else

Nothing customer-specific or project-specific may enter this repository. That means no project, customer, or engagement names; no paths, commands, tools, schemas, or domain terms from a source project; and no examples lifted from one. Every idea you bring over is **rewritten from scratch** in general terms. Never paste a passage and trim it down.

Your report to the user may say where an idea came from. Committed text may not.

## Procedure

1. **Find the copies.** Ask which directory holds the user's projects if it is not already known, then run:

   ```
   .agents/skills/harvest-skill-updates/scripts/find-skill-copies.sh <projects-dir>
   ```

   For each skill, the script groups copies by content and reports each group's status:
   - **identical to current**: nothing to harvest
   - **unchanged copy of an older version**: nothing to harvest; the project simply has not taken newer generic changes
   - **diverged**: the project changed its copy; review it
   - **predates the repository's history**: an older ancestor of the skill, compared to its closest version; skim it for ideas that were lost when the generic version was written

   It also lists skills that exist only in projects.

2. **Read each diverged copy's changes** against the version it started from:

   ```
   .agents/skills/harvest-skill-updates/scripts/find-skill-copies.sh --diff <copy-path>
   ```

   The script infers the starting version from the closest committed version that is not newer than the copy, so no one has to record it when copying. That inference is a best guess, not a fact. If the diff shows the copy *removing* text that a later generic version added, or *adding* text that a later generic version also added, the copy probably started from a different version. List the candidates with `git log --oneline -- skills/<name>/SKILL.md` and compare against one explicitly:

   ```
   .agents/skills/harvest-skill-updates/scripts/find-skill-copies.sh --diff <copy-path> <commit>
   ```

   Only `SKILL.md` is compared; list the copy's skill directory to check for added scripts or references.

3. **Classify every change** in the diff:
   - **General improvement**: a rule, check, or procedure step that would help in any project
   - **Project-specific**: depends on the project's tools, layout, or domain. Leave it.
   - **Generalizable**: project-specific as written, but an instance of a general pattern (e.g. a project's checklist of files to touch when adding a new payment method is an instance of "a new entry of a kind listed in several places"). Harvest the pattern, not the instance.
   - **Lost or regressed**: the copy dropped something the generic version still needs. Usually not a harvest item; note it only if the removal looks deliberate and the reason applies generally.
   - **Already covered**: the generic version says the same thing.

4. **Review new-skill candidates.** For skills that exist only in projects, decide whether a general version would be useful beyond its project. Two or more projects independently writing the same procedure is a strong signal. A skill that is mostly a project-specific test plan or reference is not.

5. **Report before editing.** For each proposed change, give: the target skill, the idea in general terms, and the source copies. Ask the user which ideas to take. Make no edits until they approve.

6. **Apply approved ideas.** Write the new text from scratch, matching the target skill's existing style. Then:
   - Run `make lint`.
   - Search the changed files for names, paths, and terms from the source copies you read, and remove anything that slipped through.
   - Keep README.md and AGENTS.md consistent if a skill was added or its purpose changed.
   - Use `/commit-message` to write the commit message.

## Anti-patterns

- Treating divergence as a problem. Projects are meant to customize their copies.
- Copying a passage from a project's copy and editing it down. Rewrite it instead.
- Harvesting a project's conventions as general rules just because they are good conventions. A rule belongs in a generic skill only if it holds across tech stacks and projects.
- Carrying over a source project's examples, even with names changed. Write new examples.
- Editing or "updating" copies in other projects as part of a harvest.

## Related skills

- Use `/review-plan` if the approved changes are large enough to plan first.
- Use `/commit-message` once `make lint` passes.
