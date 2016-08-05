#!/usr/bin/env bash
#
# This script will generate /etc/lizardfs/mfsmaster.cfg
#
# Copyright (c) Asher256
# License: Apache 2.0
#
# URL: https://github.com/Asher256/puppet-lizardfs
#
# This source code follows the Google style guide for shell scripts:
# https://google.github.io/styleguide/shell.xml
#

set -o errexit
set -o nounset
# set -o xtrace

function bash_traceback() {
  local lasterr="$?"
  set +o xtrace
  local code="-1"
  local bash_command=${BASH_COMMAND}
  echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]} ('$bash_command' exited with status $lasterr)"
  if [ ${#FUNCNAME[@]} -gt 2 ]; then
    # Print out the stack trace described by $function_stack
    echo "Traceback of ${BASH_SOURCE[1]} (most recent call last):"
    for ((i=0; i < ${#FUNCNAME[@]} - 1; i++)); do
    local funcname="${FUNCNAME[$i]}"
    [ "$i" -eq "0" ] && funcname=$bash_command
    echo -e "  ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]}\t$funcname"
    done
  fi
  echo "Exiting with status ${code}"
  exit "${code}"
}

# provide an error handler whenever a command exits nonzero
trap 'bash_traceback' ERR

# propagate ERR trap handler functions, expansions and subshells
set -o errtrace

main() {
  local personality
  personality=$(head -n 1 < /etc/lizardfs/.mfsmaster_personality)

  {
    cat /etc/lizardfs/.mfsmaster.header.cfg
    echo "PERSONALITY = $personality"
  } > /etc/lizardfs/mfsmaster.cfg
  echo "SUCCESS: '/etc/lizardfs/mfsmaster.cfg' was generated successfully."

  exit 0
}

# MAIN
main "$@"

# vim:ai:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=indent
