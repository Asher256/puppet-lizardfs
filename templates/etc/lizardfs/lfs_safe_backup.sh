#!/usr/bin/env bash
#
# This script will help you backup some LizardFS files.
# It can tar + gz a list of files to a .tar.gz destination.
#
# Features:
#    1. The script waits until the source files aren't open by a process
#    (because if you want, for example, to backup metadata.mfs, it is better to
#    wait until it is closed).
#    2. It uses pigz to compress the backuped files (very fast on a multi-cpu
#    server).
#
# Author: Achraf Cherti (aka Asher256) <asher256@gmail.com>
#
# This source code follows the Google style guide for shell scripts:
# https://google.github.io/styleguide/shell.xml
#
# Example
# -------
# Hourly backup (for the last 24h):
#     lfs_backup_metadata "/var/lib/lizardfs/metadata.mfs.1" "/opt/backup/lizardfs-metadata/metadata.mfs-hour-$(date +%0H).tar.gz"
#

set -o errexit
set -o nounset
# set -o xtrace

#
# TRACEBACK
#
function bash_traceback() {
  local lasterr="$?"
  set +o xtrace
  local code="-1"
  local bash_command=${BASH_COMMAND}
  echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]} ('$bash_command' exited with status $lasterr)" >&2
  if [ ${#FUNCNAME[@]} -gt 2 ]; then
    # Print out the stack trace described by $function_stack
    echo "Traceback of ${BASH_SOURCE[1]} (most recent call last):" >&2
    for ((i=0; i < ${#FUNCNAME[@]} - 1; i++)); do
    local funcname="${FUNCNAME[$i]}"
    [ "$i" -eq "0" ] && funcname=$bash_command
    echo -e "  ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]}\t$funcname" >&2
    done
  fi
  echo "Exiting with status ${code}" >&2
  exit "${code}"
}
trap 'bash_traceback' ERR
set -o errtrace

#
# CHECK_ERRORS
#
check_errors() {
  if [[ "$(id -u)" -ne "0" ]]; then
    echo "ERROR: You need to be root to run this script '$0'." >&2
    exit 1
  fi

  local path

  # check if all source files exist
  for path in "${BACKUP_SOURCE_FILES[@]}"; do
    if ! [[ -e "$path" ]]; then
      echo "ERROR: the path '$path' does not exist." >&2
      exit 1
    fi
  done

  # check the directory of the destination file
  path=''
  path=$(readlink -e "$BACKUP_DEST_FILE" || true)
  path=$(dirname "$path" || true)
  if [[ "$path" == "" ]] || ! [[ -d "$path" ]]; then
    echo "ERROR: the directory '$BACKUP_DEST_FILE' does not exist." >&2
    exit 1
  fi

  # check the extension
  if ! [[ $BACKUP_DEST_FILE =~ \.tar\.gz$ ]]; then
    echo "ERROR: the extension of '$BACKUP_DEST_FILE' needs to be '.tar.gz'." >&2
    exit 1
  fi

  local cmd
  # pigz: for the compression (multi-cpu)
  # lsof: for the function wait_until_closed
  for cmd in pigz lsof; do
    if ! which "$cmd" >/dev/null 2>&1; then
      echo "You need to install '$cmd' with: apt-get install $cmd" >&2
      exit 1
    fi
  done
}

#
# WAIT until the file is closed
#
wait_until_closed() {
  local filename="$1"

  local end
  local file_closed=0

  if lsof "$filename" >/dev/null 2>&1; then
    echo "Waiting until the file '$filename' is closed..." >&2
  fi

  end=$((SECONDS+60))
  while (( SECONDS < end )); do
    if ! lsof "$filename" >/dev/null 2>&1; then
      file_closed=1
      break
    fi

    sleep 1
  done

  if [[ "$file_closed" -eq 0 ]]; then
    echo "ERROR: The file '$filename' was open by another process for a long time..." >&2
    lsof "$filename"
    echo
    exit 1
  fi
}

#
# ATEXIT
#
atexit() {
  local errno="$?"

  # Only of BACKUP_DEST_FILE is declared
  if [[ "${BACKUP_DEST_FILE:-}" != '' ]]; then
    if [[ $SUCCESS -ne 1 ]] && [[ -f $BACKUP_DEST_FILE ]]; then
      echo "[DELETING] $BACKUP_DEST_FILE"
    fi
  fi

  exit "$errno"
}

trap 'atexit' INT TERM EXIT QUIT

#
# MAIN
#
main() {
  SUCCESS=0

  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <FILE1> <FILE2> <DIR1> ... <PATH-TO-BACKUP.gz>" >&2
    echo "" >&2
    echo "Example: $0 /var/lib/lizardfs /opt/data/backup/lizardfs-metadata-backup" >&2
    exit 1
  fi

  # The last argument is the destination
  BACKUP_DEST_FILE=${*:${#@}}

  # The source is all arguments except the last one
  BACKUP_SOURCE_FILES=(${@:1:$(($#-1))})

  check_errors

  # wait until the source file is closed
  # wait_until_closed "$BACKUP_SOURCE_FILES"

  # backup the file
  echo "[BACKUP] ${BACKUP_SOURCE_FILES[*]} --> ${BACKUP_DEST_FILE}"
  #if tar -c --use-compression-program=pigz -f "$BACKUP_DEST_FILE" "$BACKUP_SOURCE_FILES"; then
  if tar --verbose -c -f - "${BACKUP_SOURCE_FILES[@]}" | pigz --stdout > "$BACKUP_DEST_FILE"; then
    echo
    echo "[BACKUP SUCCESSFUL] $BACKUP_DEST_FILE"
    SUCCESS=1
  else
    echo
    echo "[BACKUP FAILED] $BACKUP_DEST_FILE"
  fi

  exit 0
}

# MAIN
main "$@"

# quicktest: scp % inf-p-vcg002.mdc.gameloft.org:/root/
# vim:ai:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
