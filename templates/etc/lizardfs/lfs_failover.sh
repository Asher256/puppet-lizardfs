#!/usr/bin/env bash
#
# lfs_failover.sh
# Script used by keepalived to provide a highly-available LizardFS
#
# Author: Asher256 <asher256@gmail.com>
#
# This source code follows the Google style guide for shell scripts:
# https://google.github.io/styleguide/shell.xml
#

set -o errexit
set -o nounset
# set -o xtrace

ACTION=''

if which systemctl >/dev/null 2>&1; then
  if mfsmaster isalive && ! systemctl status lizardfs-master >/dev/null 2>&1; then
    # mfsmaster was started without systemd, with "mfsmaster reload", "mfsmaster start", etc.
    SYSTEMD_ENABLED=0
  else
    # use systemd. For example: "systemctl start lizardfs-master"
    SYSTEMD_ENABLED=1
  fi
else
  # use only commands like "mfsmaster reload", "mfsmaster start", etc.
  SYSTEMD_ENABLED=0
fi

logging_info() {
  logger -p daemon.info -t "lizardfs-failover-$ACTION" "$*" || true
  echo "$*"
  return 0
}

function bash_traceback() {
  local lasterr="$?"
  set +o xtrace
  local code="-1"
  local bash_command=${BASH_COMMAND}
  logging_info "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]} ('$bash_command' exited with status $lasterr)"
  if [ ${#FUNCNAME[@]} -gt 2 ]; then
    # Print out the stack trace described by $function_stack
    echo "Traceback of ${BASH_SOURCE[1]} (most recent call last):"
    for ((i=0; i < ${#FUNCNAME[@]} - 1; i++)); do
    local funcname="${FUNCNAME[$i]}"
    [ "$i" -eq "0" ] && funcname=$bash_command
    echo -e "  ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]}\t$funcname"
    done
  fi
  logging_info "Exiting with status ${code}"
  exit "${code}"
}

# provide an error handler whenever a command exits nonzero
trap 'bash_traceback' ERR

# propagate ERR trap handler functions, expansions and subshells
set -o errtrace

stop_mfsmaster() {
  if pidof mfsmaster >/dev/null 2>&1; then
    logging_info "Stopping mfsmaster"
    # we don't use systemd in the stop because if someone start LizardFS with 'mfsmaster start'
    # (instead of systemctl start lizardfs-master) systemd will not be able to stop it.
    #if [ "$SYSTEMD_ENABLED" -eq 1 ]; then
      # non blocking stop
    #  ( systemctl stop lizardfs-master || true ) &
    #else
    # non blocking stop
    ( mfsmaster stop || true ) &
    #fi
  else
    logging_info "[IGNORED] stopping mfsmaster because it is already stopped"
  fi

  return 0
}

reload_mfsmaster() {
  logging_info "Reloading mfsmaster"
  if [ "$SYSTEMD_ENABLED" -eq 1 ]; then
    systemctl reload lizardfs-master || true
  else
    mfsmaster reload || true
  fi

  return 0
}

start_mfsmaster() {
  if pidof mfsmaster >/dev/null 2>&1; then
    logging_info "Warning: 'mfsmaster start' ignored because mfsmaster is already running"
    return 0
  fi

  logging_info "Starting mfsmaster"
  if [ "$SYSTEMD_ENABLED" -eq 1 ]; then
    systemctl start lizardfs-master || true
  else
    mfsmaster start || true
  fi

  return 0
}

#
# Wait until a process is closed
#
start_when_mfsmaster_stopped() {
  logging_info "Waiting until mfsmaster is stopped..."

  local end
  end=$((SECONDS+60))
  while (( SECONDS < end )); do
    ! pidof mfsmaster >/dev/null 2>&1 && break
    sleep "0.5"
  done

  if pidof mfsmaster >/dev/null 2>&1; then
    logging_info "[LIZARDFS FAILOVER ERROR] failed to stop mfsmaster. mfsmaster need to be stopped and started manually."
    exit 1
  fi

  return 0
}

main() {
  logging_info "[LIZARDFS FAILOVER STARTED] $0 $*"

  if [ "$#" -lt 1 ]; then
    logging_info "Usage: $0 [to_master|to_shadow]"
    exit 1
  fi

  # CHECK the validity
  ACTION="$1"
  if [ "$1" != "to_master" ] && [ "$1" != "to_shadow" ]; then
    logging_info "ERROR: you need to specify in the first argument 'to_master' or 'to_shadow'"
    exit 1
  fi

  CURRENT_PERSONALITY=$(head -n 1 < '<%= @mfsmaster_personality %>')
  if [ "$CURRENT_PERSONALITY" != "MASTER" ] && [ "$CURRENT_PERSONALITY" != "SHADOW" ]; then
    # TODO to something
    logging_info "ERROR: the file <%= @mfsmaster_personality %> doesn't contain 'MASTER' or 'SHADOW'."
    exit 1
  fi

  case "$1" in
    to_master)
      NEW_PERSONALITY="MASTER"
      ;;
    to_shadow)
      NEW_PERSONALITY="SHADOW"
      ;;
  esac

  # ONLY FOR to_shadow: don't switch two times (because keepalived will trigger this script in case of
  # a failure + in case of a backup state)
  # if [ "$CURRENT_PERSONALITY" == "SHADOW" ] && [ "$CURRENT_PERSONALITY" == "$NEW_PERSONALITY" ]; then
  #   logging_info "[IGNORED] $0 will not switch to '$ACTION' because it is already $NEW_PERSONALITY"
  #   exit 0
  # fi

  logging_info "[LIZARDFS FAILOVER] Changing mfsmaster to $NEW_PERSONALITY"
  '<%= @script_generate_mfsmaster %>' "$NEW_PERSONALITY" >/dev/null
  if [ "$NEW_PERSONALITY" = "MASTER" ]; then
    if ! pidof mfsmaster >/dev/null 2>&1; then
      start_mfsmaster
    else
      # from shadow to master, we can to a reload!
      reload_mfsmaster
    fi
  else
    stop_mfsmaster
    start_when_mfsmaster_stopped
    start_mfsmaster
  fi

  logging_info "[SUCCESS] switched to $NEW_PERSONALITY successfully"

  exit 0
}

# MAIN
main "$@"

# vim:ai:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8:foldmethod=indent
