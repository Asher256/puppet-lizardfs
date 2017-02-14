#!/usr/bin/env bash
#
# Script to help you backup your LizardFS Metadata
# (hourly backups + daily backups).
#
# Author: Achraf Cherti (aka Asher256) <asher256@gmail.com>
#
# This source code follows the Google style guide for shell scripts:
# https://google.github.io/styleguide/shell.xml
#
# Example
# -------
# Hourly backup (for the last 24h):
#     lfs_backup_metadata "/var/lib/lizardfs/metadata.mfs.1" "/opt/backup/lizardfs-metadata/metadata.mfs-hour-$(date +%0H).gz"
#

set -o errexit
set -o nounset
# set -o xtrace

#
# CHECK_ERRORS
#
check_errors() {
  if [[ "$(id -u)" -ne "0" ]]; then
    echo "ERROR: You need to be root to run this script '$0'." >&2
    exit 1
  fi

  if ! [  -f "$LFS_METADATA_SOURCE" ]; then
    echo "ERROR: the file '$LFS_METADATA_SOURCE' does not exist." >&2
    exit 1
  fi

  local cmd
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
SUCCESS=0
atexit() {
  local errno="$?"

  # Only of LFS_METADATA_DEST is declared
  if [[ "${LFS_METADATA_DEST:-}" != '' ]]; then
    if [[ $SUCCESS -ne 1 ]] && [[ -f $LFS_METADATA_DEST ]]; then
      echo "[DELETING] $LFS_METADATA_DEST"
    fi
  fi

  exit "$errno"
}

trap 'atexit' INT TERM EXIT QUIT

#
# MAIN
#
main() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <LIZARDFS-METADATA-PATH> <PATH-TO-BACKUP.gz>" >&2
    echo "" >&2
    echo "Example: $0 /var/lib/lizardfs /opt/data/backup/lizardfs-metadata-backup" >&2
    exit 1
  fi

  # DYNAMIC VARIABLES
  LFS_METADATA_SOURCE="$1"
  LFS_METADATA_DEST="$2"

  check_errors
  # wait until the source file is closed
  wait_until_closed "$LFS_METADATA_SOURCE"

  # backup the file
  echo "[BACKUP] $LFS_METADATA_SOURCE --> $LFS_METADATA_DEST"
  if pigz --force --stdout "$LFS_METADATA_SOURCE" > "$LFS_METADATA_DEST"; then
    echo
    echo "[BACKUP SUCCESSFUL] $LFS_METADATA_DEST"
    SUCCESS=1
  else
    echo
    echo "[BACKUP FAILED] $LFS_METADATA_DEST"
  fi

  exit 0
}

# MAIN
main "$@"

# quicktest: scp % inf-p-vcg002.mdc.gameloft.org:/root/
# vim:ai:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
