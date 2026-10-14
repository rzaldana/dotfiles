#!/usr/bin/env bash
#
# Library for parsing cli options


function opts::init_spec() {
  printf "%s" "{}" \
    | jq '.opts={}' \
    | jq '.description=""' \
    | jq '.name=""'
}

function opts::add_name() {
  local name 
  name="$1"
  jq --arg name "$name" '.name=$name'
}

function opts::add_description() {
  local description
  description="$1"
  jq --arg description "$description" '.description=$description'
}

function opts::add_opt() {
  local flag 
  local variable 
  local description
  local with_arg
  flag="$1"
  variable="$2"
  description="$3"
  with_arg='false'

  if [[ "$flag" == "h" ]]; then
    echo "flag is reserved for help message: -h" >&2
    return 1
  fi
  
  local opt_spec
  opt_spec="$(echo "{}" \
    | jq --arg variable "$variable" '.variable=$variable' \
    | jq --arg description "$description" '.description=$description' \
    | jq --argjson with_arg "$with_arg" '.with_arg=$with_arg'
  )"

  jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec'
}


function __opts::add_help_opt() {
  flag="h"
  variable="__OPTS_HELP"
  description="show help message"
  with_arg='false'
  
  local opt_spec
  opt_spec="$(echo "{}" \
    | jq --arg variable "$variable" '.variable=$variable' \
    | jq --arg description "$description" '.description=$description' \
    | jq --argjson with_arg "$with_arg" '.with_arg=$with_arg'
  )"

  jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec'
}


function opts::add_opt_with_arg() {
  local flag 
  local variable 
  local description
  local with_arg
  flag="$1"
  variable="$2"
  description="$3"
  with_arg='true'
  
  local opt_spec
  opt_spec="$(echo "{}" \
    | jq --arg variable "$variable" '.variable=$variable' \
    | jq --arg description "$description" '.description=$description' \
    | jq --argjson with_arg "$with_arg" '.with_arg=$with_arg'
  )"

  jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec'
}

function opts::parse() {
  local spec
  read -rd '' spec || true 

  # Add -h option for help
  spec="$( __opts::add_help_opt <<<"$spec" )"

  local -a option_flags
  mapfile -t option_flags < <(jq --raw-output --monochrome-output '.opts | keys[]' <<<"$spec")

  local -a folded_description
  mapfile -t folded_description < <(jq --raw-output --monochrome-output '.description' <<<"$spec" | fold --spaces)


  local command_name
  command_name="$(jq -rM '.name' <<<"$spec")"
  local usage
  usage="Usage: $command_name [options]"

  # Generate optstring and help message
  local optstring=':'
  local with_arg
  local -a options_help
  local opt_desc
  local opt_var

  for flag in "${option_flags[@]}"; do
    with_arg="$(jq -rM --arg flag "$flag" '.opts.[$flag].with_arg' <<<"$spec")"
    opt_desc="$(jq -rM --arg flag "$flag" '.opts.[$flag].description' <<<"$spec")"
    opt_var="$(jq -rM --arg flag "$flag" '.opts.[$flag].variable' <<<"$spec")"
    if [[ "$with_arg" == "true" ]]; then
      optstring="${optstring}${flag}:"
      options_help+=( "$(printf "  %-20s%s" "-$flag $opt_var" "$opt_desc")"  )
    else
      optstring="${optstring}${flag}"
      options_help+=( "$(printf "  %-20s%s" "-$flag" "$opt_desc")"  )
    fi
  done


  
  local -ga help_message
  for line in "${folded_description[@]}"; do
    help_message+=("$line")  
  done
  help_message+=("")
  help_message+=("$usage")
  help_message+=("")
  help_message+=("Options:")
  for line in "${options_help[@]}"; do
    help_message+=("$line")  
  done
  help_message+=("")
  help_message+=("Use \"$command_name -h\" to show this help message")

  #shellcheck disable=SC2317
  function usage() {
    for line in "${help_message[@]}"; do
      printf "%s\n" "$line"
    done
  }

  # process command line arguments
  while getopts "$optstring" opt; do
    if [[ "$opt" == '?' ]]; then
      printf "%s\n" "$0: invalid option:  $OPTARG"
      return 1
    fi

    if [[ "$opt" == ':' ]]; then
      printf "%s\n" "$0: option requires an argument: -$OPTARG"
      return 1
    fi

    if [[ "$opt" == 'h' ]]; then
      usage
      return 0
    fi

    unset -n __optvar
    local -n __optvar
    __optvar="$(jq -rM --arg flag "$opt" '.opts.[$flag].variable' <<<"$spec")"

    local has_arg
    has_arg="$(jq -rM --arg flag "$opt" '.opts.[$flag].with_arg' <<<"$spec")"
    if [[ "$has_arg" == "true" ]]; then
      __optvar="$OPTARG"
    else
      __optvar="0"
    fi
  done
  
  # remove all processed args from list of args
  shift "$((OPTIND-1))" 
}


