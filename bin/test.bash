#!/usr/bin/env bash

set -euo pipefail
source ./opts.bash
source ./std.bash

std::enable_error_trace

opts::parse "$@" < <(
  opts::init_spec \
    | opts::add_description "my descripiton is actually quite long and it will keep getting longer until the end of time you see" \
    | opts::add_opt_with_arg "l" "log_level" "add a log level" \
    | opts::add_opt "x" "tracing" "enable tracing" \
    | opts::add_name "mycli" \
)


if [[ -v log_level ]]; then
  echo "log_level is set"
else
  echo "log level is not set"
fi

if [[ -v tracing ]]; then
  echo "tracing is set"
else
  echo "tracing is not set"
fi

