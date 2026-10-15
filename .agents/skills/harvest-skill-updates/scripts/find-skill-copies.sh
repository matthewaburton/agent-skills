#!/usr/bin/env bash
# Find per-project copies of this repository's skills and compare each one
# against the generic version it most likely started from.
#
# Usage:
#   find-skill-copies.sh [--verbose] <projects-dir>
#       List copies of each skill under <projects-dir>, grouped by content.
#       --verbose also lists the paths of copies identical to the current
#       generic version (otherwise only their count is shown).
#   find-skill-copies.sh --diff <copy-path>
#       Print a unified diff from the inferred starting version to the copy.
#
# The starting version ("base") is inferred, not recorded: the copy is
# diffed against every committed version of the matching skills/<name>/SKILL.md
# and the closest one wins (ties go to the newest commit). A copy is matched to
# a generic skill by its frontmatter `name`, falling back to its directory name.
#
# Skipped while searching: .git, node_modules, .claude/worktrees, and this
# repository itself. Only SKILL.md files are compared; sibling files in a
# skill directory (scripts/, references/, ...) are not.

set -u

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(cd "$script_dir" && git rev-parse --show-toplevel)" || {
  echo "error: script must live inside the skills repository" >&2
  exit 1
}

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

frontmatter_name() {
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    /^name:/ { sub(/^name:[ \t]*/, ""); print; exit }
  ' "$1"
}

mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"
}

format_date() {
  date -d "@$1" +%Y-%m-%d 2>/dev/null || date -r "$1" +%Y-%m-%d
}

# Print the generic skill a copy belongs to, or nothing if there is none.
match_skill() {
  local name dir cand
  name="$(frontmatter_name "$1")"
  dir="$(basename "$(dirname "$1")")"
  for cand in "$name" "$dir"; do
    if [ -n "$cand" ] && [ -f "$repo/skills/$cand/SKILL.md" ]; then
      echo "$cand"
      return
    fi
  done
}

# Print "<base-commit> <changed-lines> <dated|predates>" for a copy of the
# given skill. Commits made after the copy was last modified cannot be its
# base, so they are skipped (with a day of slack for copies that kept an
# older timestamp). If every commit is newer than the copy, the copy predates
# the repository's history and the closest version overall is reported.
infer_base() {
  local skill="$1" copy="$2" cutoff commit when lines pass
  cutoff=$(($(mtime "$copy") + 86400))
  for pass in dated predates; do
    local best_commit="" best_lines=""
    while read -r commit when; do
      [ "$pass" = dated ] && [ "$when" -gt "$cutoff" ] && continue
      lines="$(git -C "$repo" show "$commit:skills/$skill/SKILL.md" 2>/dev/null \
        | diff - "$copy" | grep -c '^[<>]')"
      if [ -z "$best_lines" ] || [ "$lines" -lt "$best_lines" ]; then
        best_commit="$commit"
        best_lines="$lines"
      fi
    done < <(git -C "$repo" log --format='%h %ct' -- "skills/$skill/SKILL.md")
    if [ -n "$best_commit" ]; then
      echo "$best_commit $best_lines $pass"
      return
    fi
  done
}

latest_commit() {
  git -C "$repo" log -1 --format=%h -- "skills/$1/SKILL.md"
}

if [ "${1:-}" = "--diff" ]; then
  [ $# -eq 2 ] || usage
  copy="$2"
  [ -f "$copy" ] || { echo "error: no such file: $copy" >&2; exit 1; }
  skill="$(match_skill "$copy")"
  [ -n "$skill" ] || { echo "error: $copy does not match any skill in $repo/skills" >&2; exit 1; }
  read -r base _ _ <<<"$(infer_base "$skill" "$copy")"
  git -C "$repo" show "$base:skills/$skill/SKILL.md" \
    | diff -u --label "$skill@$base" --label "$copy" - "$copy"
  exit 0
fi

verbose=0
if [ "${1:-}" = "--verbose" ]; then
  verbose=1
  shift
fi
[ $# -eq 1 ] || usage
[ -d "$1" ] || { echo "error: not a directory: $1" >&2; exit 1; }
projects="$(cd "$1" && pwd -P)"
# When run from a linked worktree, also skip the main checkout.
main_checkout="$(cd "$(git -C "$repo" rev-parse --git-common-dir)/.." && pwd -P)"

records="$(mktemp)"
trap 'rm -f "$records"' EXIT

# One tab-separated record per copy: skill, name, hash, mtime, path.
# skill is "-" when the copy matches no generic skill.
find "$projects" \( -name .git -o -name node_modules -o -path '*/.claude/worktrees' -o -path "$repo" -o -path "$main_checkout" \) -prune \
  -o -name SKILL.md -type f -print 2>/dev/null |
  while IFS= read -r f; do
    skill="$(match_skill "$f")"
    name="$(frontmatter_name "$f")"
    [ -n "$name" ] || name="$(basename "$(dirname "$f")")"
    printf '%s\t%s\t%s\t%s\t%s\n' "${skill:--}" "$name" "$(git hash-object "$f")" "$(mtime "$f")" "$f"
  done >"$records"

echo "Skill copies under $projects"
echo "Compared against $repo/skills"

for skill in $(cut -f1 "$records" | grep -v '^-$' | sort -u); do
  latest="$(latest_commit "$skill")"
  echo
  echo "== $skill (current: $latest)"
  # Content groups, newest copy first.
  for hash in $(awk -F'\t' -v s="$skill" '$1 == s { print $4 "\t" $3 }' "$records" \
      | sort -t"$(printf '\t')" -k1,1nr | cut -f2 | awk '!seen[$0]++'); do
    paths="$(awk -F'\t' -v s="$skill" -v h="$hash" '$1 == s && $3 == h { print $5 }' "$records")"
    count="$(echo "$paths" | wc -l | tr -d ' ')"
    newest="$(awk -F'\t' -v s="$skill" -v h="$hash" '$1 == s && $3 == h { print $4 }' "$records" | sort -nr | head -n 1)"
    read -r base lines dating <<<"$(infer_base "$skill" "$(echo "$paths" | head -n 1)")"

    if [ "$lines" -eq 0 ] && [ "$base" = "$latest" ]; then
      echo "  identical to current: $count copy(ies)"
      [ "$verbose" -eq 1 ] && echo "$paths" | sed 's/^/      /'
      continue
    fi

    if [ "$dating" = predates ]; then
      status="predates the repository's history: $lines line(s) differ from the closest version, $base"
    elif [ "$lines" -eq 0 ]; then
      status="unchanged copy of $base; generic version has changed since"
    else
      status="diverged: $lines line(s) changed vs base $base"
      [ "$base" != "$latest" ] && status="$status; generic version has changed since $base"
    fi
    echo "  $status; newest $(format_date "$newest"); $count copy(ies)"
    echo "$paths" | sed 's/^/      /'
  done
done

unmatched="$(awk -F'\t' '$1 == "-"' "$records")"
if [ -n "$unmatched" ]; then
  echo
  echo "== Skills with no generic version (new-skill candidates)"
  echo "$unmatched" | sort -t"$(printf '\t')" -k2,2 -k4,4nr | while IFS="$(printf '\t')" read -r _ name _ when path; do
    echo "  $name  $(format_date "$when")  $path"
  done
fi
