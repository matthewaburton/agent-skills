#!/usr/bin/env bash
# Lint skill files and the skills tables in README.md and AGENTS.md.
#
# Checks every skills/*/SKILL.md and .agents/skills/*/SKILL.md for:
#   - YAML frontmatter with `name` and `description`
#   - `name` matching the skill's directory name
#   - a description that mentions the slash command (`/<name>`)
#   - ASCII-only content
# Then checks that the "Available skills" tables in README.md and AGENTS.md
# list exactly the skills under skills/ and are identical to each other, and
# that the prose sections the two files share are identical.
#
# Usage: scripts/lint-skills.sh   (run from anywhere inside the repo)

set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1

failures=0
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# Print the value of a top-level frontmatter key. Supports plain one-line
# values and folded/literal block values (`key: >` followed by indented lines).
frontmatter_value() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR == 1 { next }
    in_block {
      if ($0 ~ /^[ \t]+/) { sub(/^[ \t]+/, ""); value = value (value == "" ? "" : " ") $0; next }
      in_block = 0
    }
    index($0, key ":") == 1 {
      rest = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", rest)
      if (rest ~ /^[>|][-+]?$/) { in_block = 1; value = ""; next }
      value = rest
    }
    END { print value }
  ' "$1"
}

skill_files=()
for f in skills/*/SKILL.md .agents/skills/*/SKILL.md; do
  [ -f "$f" ] && skill_files+=("$f")
done

if [ "${#skill_files[@]}" -eq 0 ]; then
  fail "no SKILL.md files found"
fi

for f in "${skill_files[@]}"; do
  dir_name="$(basename "$(dirname "$f")")"

  if [ "$(head -n 1 "$f")" != "---" ]; then
    fail "$f: missing YAML frontmatter"
    continue
  fi

  name="$(frontmatter_value "$f" name)"
  description="$(frontmatter_value "$f" description)"

  [ -n "$name" ] || fail "$f: frontmatter has no name"
  [ -n "$description" ] || fail "$f: frontmatter has no description"

  if [ -n "$name" ] && [ "$name" != "$dir_name" ]; then
    fail "$f: name '$name' does not match directory '$dir_name'"
  fi

  case "$description" in
    *"/$dir_name"*) ;;
    *) fail "$f: description does not mention /$dir_name" ;;
  esac

  non_ascii="$(LC_ALL=C grep -n "$(printf '[\200-\377]')" "$f")"
  if [ -n "$non_ascii" ]; then
    fail "$f: non-ASCII characters on lines: $(echo "$non_ascii" | cut -d: -f1 | paste -sd, -)"
  fi
done

# Print the table rows of the "## Available skills" section of a file.
skills_table() {
  awk '
    /^## / { in_section = ($0 == "## Available skills"); next }
    in_section && /^\|/ { print }
  ' "$1"
}

# Print the skill names listed in a table (first column, in backticks).
table_skill_names() {
  skills_table "$1" | sed -n 's/^| *`\([^`]*\)`.*/\1/p' | sort
}

expected="$(for d in skills/*/; do basename "$d"; done | sort)"

for doc in README.md AGENTS.md; do
  if [ ! -f "$doc" ]; then
    fail "$doc: file not found"
    continue
  fi
  listed="$(table_skill_names "$doc")"
  if [ -z "$listed" ]; then
    fail "$doc: no \"## Available skills\" table found"
  elif [ "$listed" != "$expected" ]; then
    fail "$doc: skills table does not match skills/ ($(diff <(echo "$expected") <(echo "$listed") | grep '^[<>]' | paste -sd' ' -))"
  fi
done

if [ -f README.md ] && [ -f AGENTS.md ] && [ "$(skills_table README.md)" != "$(skills_table AGENTS.md)" ]; then
  fail "README.md and AGENTS.md skills tables differ"
fi

# Print the body of a "## <heading>" section of a file.
section() {
  awk -v heading="## $2" '
    /^## / { in_section = ($0 == heading); next }
    in_section { print }
  ' "$1"
}

# Sections README.md and AGENTS.md both carry and must keep word for word.
shared_sections=("Skill structure" "Customizing copies" "Writing new skills" "Maintaining this repository")

if [ -f README.md ] && [ -f AGENTS.md ]; then
  for heading in "${shared_sections[@]}"; do
    readme_section="$(section README.md "$heading")"
    agents_section="$(section AGENTS.md "$heading")"
    if [ -z "$readme_section" ] || [ -z "$agents_section" ]; then
      fail "\"## $heading\" section missing from README.md or AGENTS.md"
    elif [ "$readme_section" != "$agents_section" ]; then
      fail "\"## $heading\" differs between README.md and AGENTS.md (first difference at section line $(diff <(echo "$readme_section") <(echo "$agents_section") | head -n 1 | sed 's/[^0-9].*//'))"
    fi
  done
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures problem(s) found"
  exit 1
fi

echo "OK: ${#skill_files[@]} skill(s) checked"
