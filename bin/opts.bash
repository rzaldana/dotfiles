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
  local -a option_flags
  mapfile -t option_flags < <(jq --raw-output --monochrome-output '.opts | keys[]' <<<"$spec")

  local main_description
  main_description="$(jq --raw-output --monochrome-output '.description' <<<"$spec")"

  local -a help_message 
  mapfile -t help_message < <( fold --spaces <<<"$main_description" )
  help_message+=("")


  local usage
  usage="Usage: $(jq -rM '.name' <<<"$spec")"
  local n_opts
  n_opts="$(jq -rM '.opts | keys | length' <<<"$spec")"
  if (( n_opts > 0 )); then
    usage="$usage [options]"
  fi

  local optstring=':'
  local with_arg
  local -a options_help
  local opt_desc
  local opt_var

  # Generate optstring and help message
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

  echo "$optstring"
  echo "${usage[@]}"
  for msg in "${options_help[@]}"; do
    echo "$msg"
  done

  while getopts "$optstring" opt; do
    if [[ "$opt" == '?' ]]; then
      printf "%s\n" "$0: invalid option:  $OPTARG"
      return 1
    fi

    if [[ "$opt" == ':' ]]; then
      printf "%s\n" "$0: option requires an argument: -$OPTARG"
      return 1
    fi

    local -n __optvar
    __optvar="$(jq -rM --arg flag "$opt" '.opts.[$flag].variable' <<<"$spec")"

    local has_arg
    has_arg="$(jq -rM --arg flag "$opt" '.opts.[$flag].with_arg' <<<"$spec")"
    if [[ "$has_arg" == "true" ]]; then
      echo "setting $__optvar to $OPTARG"
      __optvar="$OPTARG"
    else
      __optvar="0"
    fi
  done
}


