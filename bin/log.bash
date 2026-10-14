#!/usr/bin/env bash
#
# Simple logging library for bash scripts

declare -gA __LOG_LEVELS=([OFF]=0 [FATAL]=1 [ERROR]=2 [WARN]=3 [INFO]=4 [DEBUG]=5)
declare -g __LOG_VERBOSITY="3"

################################################################################
# Prints a log message to stdout if the requested level is allowed by the
# current verbosity. Verbosity for this function is set with the 
# log::set_level function.
# Arguments:
#   log level (one of 'OFF', 'FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG') 
#   message to log
# Outputs:
#   log message on stdout 
# Returns:
#   1 if the requested log level is not valid, 0 otherwise
################################################################################
function log::log() {
  local log_level
  log_level="${1}"
  local message
  message="$2"

  # Check that requested level exists
  local log_level_all_caps
  log_level_all_caps="${log_level^^}"
  if ! [[ -v __LOG_LEVELS[${log_level_all_caps}] ]]; then
    std::error "invalid log level: $log_level"
  fi
  local log_verbosity
  log_verbosity="${__LOG_LEVELS[$log_level_all_caps]}"
  if (( log_verbosity  <= __LOG_VERBOSITY )); then
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
function log::set_level() {
  local log_level
  log_level="$1"
  local log_level_all_caps
  log_level_all_caps="${log_level^^}"
  if ! [[ -v "__LOG_LEVELS[${log_level_all_caps}]" ]]; then
    std::error "invalid log level: $log_level"
  fi

  local verbosity
  verbosity="${__LOG_LEVELS[$log_level_all_caps]}"
  __LOG_VERBOSITY="$verbosity"
}
