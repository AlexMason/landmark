#!/bin/sh
# Validates the Landmark repository. Exit 0 = pass.
#
#   - every skills/*/SKILL.md has frontmatter with name == directory and a description
#   - no SKILL.md exceeds 300 lines
#   - every file a skill references under assets/ or references/ exists
#   - no unresolved <owner> placeholders outside this script (warning only, since
#     a fresh fork legitimately has them)
#   - no obvious personal data (email addresses) anywhere

set -u
cd "$(dirname "$0")/.." || exit 1

fail=0
warn=0

say_fail() { printf 'FAIL  %s\n' "$*"; fail=$((fail + 1)); }
say_warn() { printf 'WARN  %s\n' "$*"; warn=$((warn + 1)); }
say_ok()   { printf 'ok    %s\n' "$*"; }

# --- skills -----------------------------------------------------------------

for dir in skills/*/; do
  dir=${dir%/}
  skill=$(basename "$dir")
  f="$dir/SKILL.md"

  [ -f "$f" ] || { say_fail "$skill: no SKILL.md"; continue; }

  # frontmatter: first line must be ---, closed by another --- before line 20
  head -n 1 "$f" | grep -q '^---$' || { say_fail "$skill: missing frontmatter"; continue; }
  fm=$(sed -n '2,20p' "$f" | sed '/^---$/q')
  name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)

  [ "$name" = "$skill" ] || say_fail "$skill: frontmatter name '$name' != directory"
  [ -n "$desc" ]         || say_fail "$skill: empty description"
  [ ${#desc} -le 1024 ]  || say_fail "$skill: description over 1024 chars"

  lines=$(wc -l < "$f")
  [ "$lines" -le 300 ] || say_fail "$skill: SKILL.md is $lines lines (max 300)"

  # referenced bundled files must exist
  for ref in $(grep -oE '(assets|references)/[A-Za-z0-9._-]+' "$f" | sort -u); do
    [ -e "$dir/$ref" ] || say_fail "$skill: references $ref but it does not exist"
  done

  # skills must not reference other skills' files
  if grep -qE 'skills/landmark-[a-z]+/(assets|references)' "$f"; then
    say_fail "$skill: references another skill's files (skills must be self-contained)"
  fi

  say_ok "$skill ($lines lines)"
done

# --- repo-wide --------------------------------------------------------------

if grep -rlE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' --exclude-dir=.git --exclude-dir=scripts . >/dev/null 2>&1; then
  say_fail "email address found:"
  grep -rnE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' --exclude-dir=.git --exclude-dir=scripts .
fi

if grep -rl '<owner>' --exclude-dir=.git --exclude-dir=scripts . >/dev/null 2>&1; then
  say_warn "<owner> placeholder still present in: $(grep -rl '<owner>' --exclude-dir=.git --exclude-dir=scripts . | tr '\n' ' ')"
fi

[ -f docs/process.md ] || say_fail "docs/process.md missing"
[ -f INSTALL.md ]      || say_fail "INSTALL.md missing"
[ -f LICENSE ]         || say_fail "LICENSE missing"

# --- result -----------------------------------------------------------------

printf '\n%d failure(s), %d warning(s)\n' "$fail" "$warn"
[ "$fail" -eq 0 ]
