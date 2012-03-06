#!/bin/bash

#
# Dumps a database. 
#
# Usage db_dump <dbname> <dbuser> <dbpassword> <dumpdir>
#

dbname=$1
dbuser=$2
dbpass=$3
dumpdir=$4

# Check destination directory exists and is writable
if ! [ -d "$dumpdir" ] || ! [ -w "$dumpdir" ]; then
	echo "Dump directory does not exist or is not writable"
	exit 1
fi

# Determine whether this is daily/weekly/monthly based on current date
dayofmonth=`date +%d` # 01-31
dayofweek=`date +%u` # 1-7 (Monday-Sunday)

if [ $dayofmonth == "01" ]; then
	dumpfilename="${dbname}-`date '+%Y-%m-%d'`-monthly.gz"
elif [ $dayofweek == "1" ]; then
	dumpfilename="${dbname}-`date '+%Y-%m-%d'`-weekly.gz"
else
	dumpfilename="${dbname}-`date '+%Y-%m-%d'`-daily.gz"
fi 

dumpfile="$dumpdir/$dumpfilename"

# Delete dump file if it already exists
if [ -e $dumpfile ]; then
	rm $dumpfile
fi

# Dump OpenMRS database and gzip result
mysqldump -u$dbuser -p$dbpass $dbname | gzip -c > $dumpfile

# Check dump was successful
if [ ${PIPESTATUS[0]} -ne 0 ]; then
	echo "MySQL dump failed"
	exit 1
fi