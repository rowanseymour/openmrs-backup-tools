#!/bin/bash

# Get script directory
SCRIPT_PATH="${BASH_SOURCE[0]}";
if ([ -h "${SCRIPT_PATH}" ]) then
  while([ -h "${SCRIPT_PATH}" ]) do SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi
pushd . > /dev/null
cd `dirname ${SCRIPT_PATH}` > /dev/null
SCRIPT_PATH=`pwd`;
popd  > /dev/null

# Load configuration values
. $SCRIPT_PATH/backup.conf
 
DST_DIR="$USB_DEV_PATH/openmrs_backups"
 
echo "Syncing $DST_DIR with $BACKUP_DEST_DIR"
 
rsync -rt --delete "$BACKUP_DEST_DIR" "$DST_DIR"

logger -t $LOGGING_TAG -p local0.crit "Backups synced with USB device"
 
echo "Unmounting USB drive"
 
pumount $USB_DEV_PATH