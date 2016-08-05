#!/usr/bin/env bash
#
# This script will switch the PERSONALITY=MASTER/SHADOW on
# and will generate mfsmaster.cfg again, with the new personality.
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
  if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [MASTER|SHADOW]" >&2

  if [ -f /etc/lizardfs/.mfsmaster_personality ]; then
    local personality
    personality=$(cat /etc/lizardfs/.mfsmaster_personality)

    echo
    echo "(current personality: $personality)"
  fi

    exit 1
  fi

  if [ "$1" != "MASTER" ] && [ "$1" != "SHADOW" ]; then
    echo "ERROR: the personality '$1' you provided is wrong." \
         "The allowed values: 'MASTER' or 'SHADOW' (in the upper case)." >&2
    exit 1
  fi

  echo "$1" > /etc/lizardfs/.mfsmaster_personality
  echo "SUCCESS: '/etc/lizardfs/.mfsmaster_personality' switched to $1"

  /etc/lizardfs/.generate-mfsmaster.cfg || exit 1

  exit 0
}

# MAIN
main "$@"

# vim:ai:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=indent
