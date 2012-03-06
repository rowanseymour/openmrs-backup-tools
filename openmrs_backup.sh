#!/bin/bash

# Load configuration values
. ~/openmrs_backup.conf

# Fail function to record error in syslog
fail() {
	logger -t $LOGGING_TAG -p local0.crit $1
	echo $1
	exit
}

# Check runtime properties file exists
if ! [ -e "$OPENMRS_PROP_FILE" ]; then
	fail "Specified OpenMRS runtime properties file does not exist"
fi

# Read properties from properties file
dbuser=`sed '/^\#/d' "$OPENMRS_PROP_FILE" | grep 'connection.username' | tail -n 1 | cut -d "=" -f2-`
dbpass=`sed '/^\#/d' "$OPENMRS_PROP_FILE" | grep 'connection.password' | tail -n 1 | cut -d "=" -f2-`
dburl=`sed '/^\#/d' "$OPENMRS_PROP_FILE" | grep 'connection.url' | tail -n 1 | cut -d "=" -f2-`

# Check properties could be read
if [ -z $dbuser ] || [ -z $dbpass ] || [ -z $dburl ]; then
	fail "Unable to read OpenMRS runtime properties"
fi

# Extract database name from connection URL
if [[ $dburl =~ /([a-zA-Z0-9_\-]+)\? ]]; then
        dbname=${BASH_REMATCH[1]}
else
        dbname="openmrs"
fi

# Check destination directory exists and is writable
if ! [ -d "$BACKUP_DEST_DIR" ] || ! [ -w "$BACKUP_DEST_DIR" ]; then
	fail "Backup destination directory does not exist or is not writable"
fi

# Determine whether this is daily/weekly/monthly based on current date
dayofmonth=`date +%d` # 01-31
dayofweek=`date +%u` # 1-7 (Monday-Sunday)

if [ $dayofmonth == "01" ]; then
	dumpfilename="`date '+%Y-%m-%d'`-openmrsdb-monthly.gz"
elif [ $dayofweek == "1" ]; then
	dumpfilename="`date '+%Y-%m-%d'`-openmrsdb-weekly.gz"
else
	dumpfilename="`date '+%Y-%m-%d'`-openmrsdb-daily.gz"
fi 

dumpfile="$BACKUP_DEST_DIR/$dumpfilename"

# Delete dump file if it already exists
if [ -e $dumpfile ]; then
	rm $dumpfile
fi

# Dump OpenMRS database and gzip result
mysqldump -u$dbuser -p$dbpass $dbname | gzip -c > $dumpfile

# Check dump was successful and new dump file exists
if [ ${PIPESTATUS[0]} -eq 0 ] && [ -e $dumpfile ]; then
	logger -t $LOGGING_TAG -p local0.info "Database dump successful"
else
	fail "Unable to dump database (name=$dbname, user=$dbuser)"
fi

# Optionally delete old daily dumps
if [ $DAILY_KEEP_DAYS -ne 0 ]; then
	find "$BACKUP_DEST_DIR" -name "*-daily.gz" -type f -mtime +${DAILY_KEEP_DAYS} -delete
fi

# Optionally delete old weekly dumps
if [ $WEEKLY_KEEP_WEEKS -ne 0 ]; then
	keepdays=`expr $((($WEEKLY_KEEP_WEEKS * 7) + 1))`
	find "$BACKUP_DEST_DIR" -name "*-weekly.gz" -type f -mtime +${keepdays} -delete
fi

# Optionally delete old monthly dumps
if [ $MONTHLY_KEEP_MONTHS -ne 0 ]; then
	keepdays=`expr $((($MONTHLY_KEEP_MONTHS * 31) + 1))`
	find "$BACKUP_DEST_DIR" -name "*-monthly.gz" -type f -mtime +${keepdays} -delete
fi
