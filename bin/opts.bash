#!/usr/bin/env bash
#
# Library for parsing cli options

source std.bash

declare -g __OPTS_SPEC

function __opts::init_spec_if_not_set() {
  if ! [[ -v __OPTS_SPEC ]]; then
    __OPTS_SPEC="$(
      printf "%s" "{}" \
        | jq '.opts={}' \
        | jq '.description=""' \
        | jq '.name=""' \
        | jq '.required_args=[]'
    )"
  fi
}

function opts::add_name() {
  local name 
  name="$1"
  __opts::init_spec_if_not_set
  __OPTS_SPEC="$(jq --arg name "$name" '.name=$name' <<<"$__OPTS_SPEC")"
}

function opts::add_description() {
  local description
  description="$1"
  __opts::init_spec_if_not_set
  __OPTS_SPEC="$(jq --arg description "$description" '.description=$description' <<<"$__OPTS_SPEC")"
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
  __opts::init_spec_if_not_set

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

  __OPTS_SPEC="$(jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec' <<<"$__OPTS_SPEC")"
}

function opts::add_required_arg() {
  local arg_name
  local variable
  arg_name="$1"
  variable="$2"
  __opts::init_spec_if_not_set

  local arg_spec
  arg_spec="$( echo "{}" \
    | jq --arg name "${arg_name^^}" '.name=$name' \
    | jq --arg variable "$variable" '.variable=$variable'
  )"

  __OPTS_SPEC="$(jq --argjson arg_spec "$arg_spec" '.required_args+=[$arg_spec]' <<<"$__OPTS_SPEC")"
}


function __opts::add_help_opt() {
  flag="h"
  variable="__OPTS_HELP"
  description="show help message"
  with_arg='false'
  __opts::init_spec_if_not_set
  
  local opt_spec
  opt_spec="$(echo "{}" \
    | jq --arg variable "$variable" '.variable=$variable' \
    | jq --arg description "$description" '.description=$description' \
    | jq --argjson with_arg "$with_arg" '.with_arg=$with_arg'
  )"

  __OPTS_SPEC="$(jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec' <<<"$__OPTS_SPEC")"
}


function opts::add_opt_with_arg() {
  local flag
  local arg_name
  local variable 
  local description
  local with_arg
  flag="$1"
  arg_name="${2^^}" # make argname uppercase
  variable="$3"
  description="$4"
  with_arg='true'
  __opts::init_spec_if_not_set
  
  local opt_spec
  opt_spec="$(echo "{}" \
    | jq --arg variable "$variable" '.variable=$variable' \
    | jq --arg description "$description" '.description=$description' \
    | jq --argjson with_arg "$with_arg" '.with_arg=$with_arg' \
    | jq --arg arg_name "$arg_name" '.arg_name=$arg_name' \
  )"

  __OPTS_SPEC="$(jq --arg flag "$flag" --argjson opt_spec "$opt_spec" '.opts.[$flag]=$opt_spec' <<<"$__OPTS_SPEC")"
}

function opts::parse() {
  local spec

  # Add -h option for help
  __opts::add_help_opt
  spec="${__OPTS_SPEC}"

  local -a option_flags
  mapfile -t option_flags < <(jq --raw-output --monochrome-output '.opts | keys[]' <<<"$spec")

  local -a folded_description
  mapfile -t folded_description < <(jq --raw-output --monochrome-output '.description' <<<"$spec" | fold --spaces)

  local -a required_args
  mapfile -t required_args < <(jq --compact-output --raw-output --monochrome-output '.required_args[]' <<<"$spec")


  # Create usage string
  local command_name
  command_name="$(jq -rM '.name' <<<"$spec")"
  local usage
  usage="Usage: $command_name [options]"
  for required_arg in "${required_args[@]}"; do
    usage="$usage $(jq --raw-output --monochrome-output '.name' <<<"$required_arg")"
  done

  # Generate optstring and help message
  local optstring=':'
  local with_arg
  local -a options_help
  local opt_desc

  for flag in "${option_flags[@]}"; do
    with_arg="$(jq -rM --arg flag "$flag" '.opts.[$flag].with_arg' <<<"$spec")"
    opt_desc="$(jq -rM --arg flag "$flag" '.opts.[$flag].description' <<<"$spec")"
    local arg_name
    if arg_name="$(jq \
      --arg flag "$flag" \
      --exit-status \
      --raw-output \
      --monochrome-output \
      '.opts[$flag].arg_name' \
      <<<"$spec"
      )"; then
      optstring="${optstring}${flag}:"
      options_help+=( "$(printf "  %-20s%s" "-$flag $arg_name" "$opt_desc")"  )
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

  # process options
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
      exit 0
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

  # process args
  local arg_name
  for required_arg in "${required_args[@]}"; do
    # get arg name
    arg_name="$(jq --raw-output --monochrome-output '.name' <<<"$required_arg")"
    if ! [[ -v 1 ]]; then
      std::error "required arg not set: $arg_name"
    fi
      
    unset -n __arg_var_name
    local -n __arg_var_name
    __arg_var_name="$(jq --raw-output --monochrome-output '.variable' <<<"$required_arg")"
    #shellcheck disable=SC2034
    __arg_var_name="$1"
    shift 1
  done

}


