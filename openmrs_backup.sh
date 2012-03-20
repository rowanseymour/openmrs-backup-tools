#!/bin/bash

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load configuration values
. $DIR/backup.conf

# Fail function to record error in syslog
fail() {
	logger -t $LOGGING_TAG -p local0.crit $1
	echo $1
	exit 1
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

# Dump the database
$DIR/db_dump.sh $dbname $dbuser $dbpass $BACKUP_DEST_DIR

# Check dump was successful
if [ $? -eq 0 ]; then
	logger -t $LOGGING_TAG -p local0.info "Database dump successful"
else
	fail "Unable to dump database (name=$dbname, user=$dbuser)"
fi

# Cleanup old dumps
$DIR/rotate.sh $DAILY_KEEP_DAYS $WEEKLY_KEEP_WEEKS $MONTHLY_KEEP_MONTHS $BACKUP_DEST_DIR