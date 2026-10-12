#!/usr/bin/env bash
#
# standard library of common bash functions 

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
  printf "%s\n"  "ERROR: $error_message" >&2
  return 1
}

################################################################################
# Check that the function received the expected number of args
# Arguments:
#   number of expected args
#   arguments to check
# Outputs:
#   None
# Returns:
#   0 if function received expected number of args, 1 otherwise
################################################################################
function std::check_args() {
  local n_args_expected
  n_args_expected="$1"
  shift 1
  if (( $# < n_args_expected )); then
    std::error "expected $n_args_expected args but received $#" >&2
  fi
}
