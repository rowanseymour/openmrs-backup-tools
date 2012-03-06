#!/bin/bash

#
# Cleanups old database dumps.
#
# Usage: rotate <DAILYS> <WEEKLYS> <MONTHLYS> <DUMPDIR>
#

dailys=$1
weeklys=$2
monthlys=$3
dumpdir=$4

# Optionally delete old daily dumps
if [ $dailys -ne 0 ]; then
	find "$dumpdir" -name "*-daily.gz" -type f -mtime +${dailys} -delete
fi

# Optionally delete old weekly dumps
if [ $weeklys -ne 0 ]; then
	keepdays=`expr $((($weeklys * 7) + 1))`
	find "$dumpdir" -name "*-weekly.gz" -type f -mtime +${keepdays} -delete
fi

# Optionally delete old monthly dumps
if [ $monthlys -ne 0 ]; then
	keepdays=`expr $((($monthlys * 31) + 1))`
	find "$dumpdir" -name "*-monthly.gz" -type f -mtime +${keepdays} -delete
fi