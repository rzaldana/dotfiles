---
inclusion: manual
---
# Bash Composition Conventions

Load and apply this file ONLY when explicitly asked to compose/write new bash
code. Do NOT apply it when merely reading, understanding, reasoning about, or
giving illustrative examples of bash. These are the conventions learned from
this project's `bin/std.bash`.

## Function style
- Namespace functions with a `::` prefix matching the library (e.g. `std::`).
- Precede every function with a header comment block in this exact shape:
  ```bash
  ################################################################################
  # One-line summary of what the function does.
  # Arguments:
  #   <describe each positional arg, or "None">
  # Outputs:
  #   <what it writes to stdout/stderr, or "None">
  # Returns:
  #   <exit status meaning>
  ################################################################################
  ```
- Define functions with the `function name() { ... }` form.
- Declare each local on its own line, then assign on the next line:
  ```bash
  local foo
  foo="$1"
  ```
  (Separate declare/assign so a command-substitution failure isn't masked by
  `local`'s own exit status.)
- Indent with 2 spaces, expandtab (no literal tabs).

## Variables
- Always quote expansions: `"$var"`, `"${arr[@]}"`.
- Internal/global library state uses an uppercase, double-underscore prefix,
  e.g. `__STD_LOG_VERBOSITY`.
- Associative arrays require bash 4+; `declare -A`.
- Keys of lookup/enum associative arrays are ALL-CAPS (e.g. `__LOG_LEVELS`,
  `__STD_COLORS` use keys like `ERROR`, `RED`). When a function accepts such a
  key as input, normalize the argument with `${arg^^}` before lookup so the
  input is case-insensitive, and report the user's original casing in any error
  message.
- To test whether an associative-array key exists, use `[[ -v arr[$key] ]]`
  (bash 4.3+). Do NOT quote the subscript: `[[ -v arr[$key] ]]`, not
  `[[ -v "arr[$key]" ]]`. A missing key expands to empty silently, so validate
  before use.
- When indexing an array with a variable key, include the `$`:
  `"${arr[$key]}"` — a bare `arr[key]` is treated as the literal key "key".
- Guard every read-only global (`declare -r` / `declare -gr` / `-grA`) so a
  library can be sourced multiple times idempotently. Re-declaring an existing
  read-only variable errors (and aborts under `set -e`). Only declare when it
  is not already set:
  ```bash
  if ! declare -p __STD_COLORS >/dev/null 2>&1; then
    declare -grA __STD_COLORS=( [RED]='\e[0;31m' ... )
  fi
  ```
  Use `declare -p NAME >/dev/null 2>&1` for the existence test — it works for
  scalars, indexed arrays, AND associative arrays. Do NOT use `[[ -v NAME ]]`
  for arrays: on a bare array name it tests index 0 and gives a false negative
  for associative arrays. Non-readonly globals do not need the guard (they are
  simply reassigned on re-source).

## Namerefs (`declare -n` / `local -n`, bash 4.3+)
- Prefer namerefs for "set a variable whose name is in another variable".
- The FIRST assignment to a nameref sets what it points to; SUBSEQUENT
  assignments set the target's value.
- Prefix nameref locals (e.g. `local -n _ref="$name"`) to avoid circular
  reference collisions with caller variable names.
- Alternative without eval: `printf -v "$name" '%s' "$value"`.

## Error handling & traps
- `std::error` writes `scriptname: ERROR: <msg>` to stderr and returns 1
  (returns rather than exits — let callers decide).
- For stack traces, use the `FUNCNAME` / `BASH_SOURCE` / `BASH_LINENO` arrays
  (index 0 = current frame). Capture `$?` and `$LINENO` as the FIRST action in
  an ERR trap, before any other command overwrites them.
- To make an ERR trap propagate into functions/subshells, set
  `set -o errtrace` (`set -E`).
- ALWAYS use `set -e` on every script. The standard strict-mode header for
  every bash script is:
  ```bash
  set -euo pipefail
  ```
  (`-e` exit-on-error, `-u` error on unset vars, `-o pipefail` fail on any
  pipeline member). Include this near the top of every script you compose.

### Writing every function assuming `set -e` is in effect
- Assume any command that returns non-zero will abort the script. Write
  functions so that is the intended behavior.
- A function's exit status is that of its last command; do not rely on a
  function continuing past a failed command.
- When a non-zero exit is EXPECTED and should NOT abort, handle it explicitly:
  - Guard in a conditional: `if ! some_cmd; then ...; fi` (commands tested in
    `if`/`while`/`&&`/`||` do not trigger `set -e`).
  - Or append `|| true` when you deliberately want to ignore a failure.
  - Capture status safely: `rc=0; some_cmd || rc=$?`.
- Remember `local foo="$(cmd)"` masks `cmd`'s failure under `local`'s own exit
  status, defeating `set -e`. Always split: `local foo; foo="$(cmd)"` so a
  failing command substitution still aborts.
- Be aware `set -e` is suppressed inside command substitutions in older bash
  and in any command that is part of a `&&`/`||`/`!`/`if`/`while` test — design
  around these documented exceptions.

## External CLI dependencies
- Keep the core of a shell library in pure bash builtins — no hard dependency
  on external CLIs (bootstrap/portability/startup-cost reasons).
- Prefer shell builtins first, then GNU coreutils, over third-party binaries.
  Reach for an external tool only when a builtin / coreutils cannot do the job.
- Treat tools like `logger`, `jq` as OPTIONAL: feature-detect with
  `command -v tool >/dev/null 2>&1` and degrade gracefully to a builtin
  fallback.

## jq usage (when composing bash that shells out to jq)
- Pass dynamic values with `--arg` (string) or `--argjson` (raw JSON:
  booleans, numbers, objects, arrays). Never string-concatenate values into
  the filter.
- Dynamic object key: `.[$k] = ...` for assignment, or `{ ($k): ... }` in
  object construction (parens required).
- Append to an array: `.arr += [$item]` (wrap the element in `[...]`).
- Add empty array: `.my = []`; add only if absent: `.my //= []`.
- Parse a JSON-encoded string field: `.field | fromjson` (or `.field |=
  fromjson` in place).
- Get keys: `keys` (sorted) or `keys_unsorted`; `keys[]` + `-r` for one per
  line.
- Concatenate strings with `+` (both sides strings; `tostring` to coerce), or
  use interpolation `"\(.a):\(.b)"`. Use `-r` for raw output, `-j` to join
  with no newline.
- Indexing with a bracket accepts an optional dot before it: `.opts[$flag]`
  and `.opts.[$flag]` are BOTH valid and equivalent (verified on jq 1.7.1).
  `.foo` is itself shorthand for `.["foo"]`.

## Target environment
- Write for bash 5+ ONLY. Freely use associative arrays, `${v^^}`/`${v,,}`,
  `[[ -v arr[k] ]]`, namerefs (`declare -n`), and other modern bash features
  without version guards or fallbacks for older bash. Use
  `#!/usr/bin/env bash`.
- Assume GNU coreutils are available (not BSD/macOS variants). Use GNU options
  freely, e.g. `fold -s -w N` / `fmt -w N` for wrapping text.
