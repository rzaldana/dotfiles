#!/usr/bin/env bash
#
# standard library of common bash functions 

declare -A __STD_LOG_LEVELS=([OFF]=0 [FATAL]=1 [ERROR]=2 [WARN]=3 [INFO]=4 [DEBUG]=5)
declare __STD_LOG_VERBOSITY="3"

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
# Prints a log message to stdout if the requested level is allowed by the
# current verbosity. Verbosity for this function is set with the 
# std::set_log_level function.
# Arguments:
#   log level (one of 'OFF', 'FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG') 
#   message to log
# Outputs:
#   log message on stdout 
# Returns:
#   1 if the requested log level is not valid, 0 otherwise
################################################################################
function std::log() {
  local log_level
  log_level="${1}"
  local message
  message="$2"

  # Check that requested level exists
  local log_level_all_caps
  log_level_all_caps="${log_level^^}"
  if ! [[ -v __STD_LOG_LEVELS[${log_level_all_caps}] ]]; then
    std::error "invalid log level: $log_level"
  fi
  local log_verbosity
  log_verbosity="${__STD_LOG_LEVELS[$log_level_all_caps]}"
  if (( log_verbosity  <= __STD_LOG_VERBOSITY )); then
    printf "%s %-5s %s\n" "$(std::script_name)" "${log_level_all_caps}" "$message"
  fi
}

################################################################################
# Sets the verbosity for the std::log function
# Arguments:
#   log level (one of 'OFF', 'FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG') 
# Outputs:
#   log message on stdout 
# Returns:
#   1 if the requested value is not valid, 0 otherwise
################################################################################
function std::set_log_level() {
  local log_level
  log_level="$1"
  local log_level_all_caps
  log_level_all_caps="${log_level^^}"
  if ! [[ -v "__STD_LOG_LEVELS[${log_level_all_caps}]" ]]; then
    std::error "invalid log level: $log_level"
  fi

  local verbosity
  verbosity="${__STD_LOG_LEVELS[$log_level_all_caps]}"
  __STD_LOG_VERBOSITY="$verbosity"
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
