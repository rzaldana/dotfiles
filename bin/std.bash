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
