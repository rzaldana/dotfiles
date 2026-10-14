#!/usr/bin/env bash
#
# Simple logging library for bash scripts

declare -gA __LOG_LEVELS=([OFF]=0 [FATAL]=1 [ERROR]=2 [WARN]=3 [INFO]=4 [DEBUG]=5)
declare -g __LOG_VERBOSITY="3"

# Color used to print each log level's label. OFF is absent since it is never
# printed as a message level.
declare -gA __LOG_LEVEL_COLORS=(
  [FATAL]=MAGENTA
  [ERROR]=RED
  [WARN]=YELLOW
  [INFO]=BLUE
  [DEBUG]=CYAN
)

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

  # Check that the requested level exists and is a usable message level. OFF is
  # a verbosity sentinel ("log nothing"), not a level a message can be logged
  # at, so it is rejected here.
  local log_level_all_caps
  log_level_all_caps="${log_level^^}"
  if ! [[ -v __LOG_LEVELS[${log_level_all_caps}] ]] \
    || [[ "$log_level_all_caps" == "OFF" ]]; then
    std::error "invalid log level: $log_level"
  fi
  local log_verbosity
  log_verbosity="${__LOG_LEVELS[$log_level_all_caps]}"
  if (( log_verbosity  <= __LOG_VERBOSITY )); then
    # Print the level word in its assigned color. The level is padded to a
    # fixed-width field for alignment, but the padding is printed separately
    # with "%*s" (which takes the field width as an argument) because the color
    # escape codes would otherwise be counted by printf's native "%-Ns"
    # padding and throw the alignment off.
    local level_field_width
    level_field_width=5
    local pad_len
    pad_len=$(( level_field_width - ${#log_level_all_caps} ))
    printf "%s " "$(std::script_name)"
    std::color_print "${__LOG_LEVEL_COLORS[$log_level_all_caps]}" "$log_level_all_caps"
    printf "%*s %s\n" "$pad_len" "" "$message"
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

################################################################################
# Logs a message at the FATAL level. Convenience wrapper around log::log.
# Arguments:
#   message to log
# Outputs:
#   log message on stdout (if FATAL is allowed by the current verbosity)
# Returns:
#   0 on success
################################################################################
function log::fatal() {
  local message
  message="$1"
  log::log "FATAL" "$message"
}

################################################################################
# Logs a message at the ERROR level. Convenience wrapper around log::log.
# Arguments:
#   message to log
# Outputs:
#   log message on stdout (if ERROR is allowed by the current verbosity)
# Returns:
#   0 on success
################################################################################
function log::error() {
  local message
  message="$1"
  log::log "ERROR" "$message"
}

################################################################################
# Logs a message at the WARN level. Convenience wrapper around log::log.
# Arguments:
#   message to log
# Outputs:
#   log message on stdout (if WARN is allowed by the current verbosity)
# Returns:
#   0 on success
################################################################################
function log::warn() {
  local message
  message="$1"
  log::log "WARN" "$message"
}

################################################################################
# Logs a message at the INFO level. Convenience wrapper around log::log.
# Arguments:
#   message to log
# Outputs:
#   log message on stdout (if INFO is allowed by the current verbosity)
# Returns:
#   0 on success
################################################################################
function log::info() {
  local message
  message="$1"
  log::log "INFO" "$message"
}

################################################################################
# Logs a message at the DEBUG level. Convenience wrapper around log::log.
# Arguments:
#   message to log
# Outputs:
#   log message on stdout (if DEBUG is allowed by the current verbosity)
# Returns:
#   0 on success
################################################################################
function log::debug() {
  local message
  message="$1"
  log::log "DEBUG" "$message"
}
