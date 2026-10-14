#!/usr/bin/env bash
#
# standard library of common bash functions 

# The library assumes these options are set
# Unsetting them will lead to unexpected behaviour
set -euo pipefail

################################################################################
# Print an error message to STDERR and exit with status code 1 
# Arguments:
#   error message
# Outputs:
#   Writes error message to stderr
# Returns:
#   always returns 1 
################################################################################
function std::error() {
  local error_message
  error_message="$1"
  printf "%s: %s\n"  "$(std::script_name)" "ERROR: $error_message" >&2
  return 1
}


################################################################################
# Print a success message to STDOUT
# Arguments:
#   message
# Outputs:
#   Writes success message to stdout
# Returns:
#   always returns 0 
################################################################################
function std::success() {
  local message
  message="$1"
  printf "%s: %s\n"  "$(std::script_name)" "SUCCESS: $message"
}

################################################################################
# Returns the name of the script that's currently running
# Arguments:
#   None
# Outputs:
#   None
################################################################################
function std::script_name() {
  basename "${BASH_SOURCE[-1]}"
}

################################################################################
# Prints a stack trace of the current call stack to STDERR, most recent call
# first. Each frame shows the function name, the source file, and the line
# number from which the call was made.
# Arguments:
#   number of leading frames to skip (optional, defaults to 0). Used by
#   callers such as the ERR trap to omit the trace function's own frame.
# Outputs:
#   Writes the stack trace to stderr
# Returns:
#   always returns 0
################################################################################
function std::stacktrace() {
  local skip
  skip="${1:-0}"

  printf "%s\n" "Stack trace (most recent call first):" >&2

  # FUNCNAME holds the call stack; index 0 is this function. Start one frame
  # above std::stacktrace itself, plus any additional frames to skip.
  local start
  start=$(( 1 + skip ))

  local frame
  for (( frame = start; frame < ${#FUNCNAME[@]}; frame++ )); do
    # The function at FUNCNAME[frame] was called from the line recorded in
    # BASH_LINENO[frame-1], located in the file BASH_SOURCE[frame].
    local func
    func="${FUNCNAME[frame]}"
    local source_file
    source_file="${BASH_SOURCE[frame]}"
    local line_no
    line_no="${BASH_LINENO[frame - 1]}"
    printf "  at %s (%s:%s)\n" "$func" "$source_file" "$line_no" >&2
  done
}

################################################################################
# ERR trap handler. Reports the command that failed, its exit status, and the
# location, then prints a stack trace. Intended to be installed by
# std::enable_error_trace rather than called directly.
# Arguments:
#   exit status of the failed command
#   line number where the failure occurred
#   the command that failed (typically $BASH_COMMAND)
# Outputs:
#   Writes the error report and stack trace to stderr
# Returns:
#   returns the exit status it was passed
################################################################################
function std::_on_error() {
  local exit_status
  exit_status="$1"
  local line_no
  line_no="$2"
  local failed_command
  failed_command="$3"

  printf "%s: %s\n" "$(std::script_name)" \
    "ERROR: command '${failed_command}' failed with status ${exit_status} at ${BASH_SOURCE[1]}:${line_no}" >&2

  # Skip one frame so the trace starts at the code that failed rather than at
  # this handler.
  std::stacktrace 1

  return "$exit_status"
}

################################################################################
# Installs an ERR trap that prints a stack trace whenever a command fails.
# Enables errtrace (set -E) so the trap also fires inside functions, command
# substitutions, and subshells. Call this once near the top of a script.
# Arguments:
#   None
# Outputs:
#   None (the installed trap writes to stderr when triggered)
# Returns:
#   always returns 0
################################################################################
function std::enable_error_trace() {
  # errtrace makes the ERR trap propagate into functions and subshells.
  set -o errtrace
  # Capture $? and $LINENO first; any later command would overwrite them.
  trap 'std::_on_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
}

# Color escape codes keyed by color name. Keys are all-caps to match the
# convention used by __LOG_LEVELS in log.bash. Declared read-only so they
# cannot be clobbered. "BLANK" resets to the default terminal color; "PURPLE"
# is an alias of "MAGENTA".
declare -grA __STD_COLORS=(
  [BLACK]='\e[0;30m'
  [RED]='\e[0;31m'
  [GREEN]='\e[0;32m'
  [YELLOW]='\e[0;33m'
  [BLUE]='\e[0;34m'
  [MAGENTA]='\e[0;35m'
  [PURPLE]='\e[0;35m'
  [CYAN]='\e[0;36m'
  [WHITE]='\e[0;37m'
  [BLANK]='\e[0m'
)

################################################################################
# Prints text in the named color, followed by a reset so color does not bleed
# into subsequent output. The text is printed with %s so escape sequences in
# the text itself are not interpreted. No trailing newline is added.
#
# Color codes are only emitted when stdout is connected to a terminal (TTY).
# When stdout is piped or redirected to a file (non-interactive), the text is
# printed plainly with no color codes.
# Arguments:
#   color name (one of the keys of __STD_COLORS, e.g. "red", "green");
#     matched case-insensitively, so "RED" and "rEd" also work
#   text to print
# Outputs:
#   the (optionally colorized) text on stdout, with no trailing newline
# Returns:
#   1 (via std::error) if the color name is not valid, 0 otherwise
################################################################################
function std::color_print() {
  local color_name
  color_name="$1"
  local text
  text="$2"

  # Normalize to uppercase so color names are case-insensitive (the keys of
  # __STD_COLORS are all-caps).
  local color_name_upper
  color_name_upper="${color_name^^}"

  # Reject unknown color names.
  if ! [[ -v __STD_COLORS[$color_name_upper] ]]; then
    std::error "invalid color: $color_name"
  fi

  local color_code
  color_code="${__STD_COLORS[$color_name_upper]}"

  # Only colorize when stdout is a terminal; otherwise print plainly so that
  # redirected/piped output is not polluted with escape codes.
  if [[ -t 1 ]]; then
    printf "%b%s%b" "$color_code" "$text" "${__STD_COLORS[BLANK]}"
  else
    printf "%s" "$text"
  fi
}

################################################################################
# Prints the given text in black, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_black() {
  std::color_print "BLACK" "$1"
}

################################################################################
# Prints the given text in red, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_red() {
  std::color_print "RED" "$1"
}

################################################################################
# Prints the given text in green, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_green() {
  std::color_print "GREEN" "$1"
}

################################################################################
# Prints the given text in yellow, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_yellow() {
  std::color_print "YELLOW" "$1"
}

################################################################################
# Prints the given text in blue, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_blue() {
  std::color_print "BLUE" "$1"
}

################################################################################
# Prints the given text in magenta, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_magenta() {
  std::color_print "MAGENTA" "$1"
}

################################################################################
# Prints the given text in purple (an alias of magenta), then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_purple() {
  std::color_print "PURPLE" "$1"
}

################################################################################
# Prints the given text in cyan, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_cyan() {
  std::color_print "CYAN" "$1"
}

################################################################################
# Prints the given text in white, then resets the color.
# Arguments:
#   text to print
# Outputs:
#   the text on stdout (colorized only when stdout is a terminal), no newline
# Returns:
#   0 on success
################################################################################
function std::color_white() {
  std::color_print "WHITE" "$1"
}
