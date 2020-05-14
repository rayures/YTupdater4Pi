#!/bin/bash

# original author: https://gitlab.com/grublets/youtube-updater-for-pi-hole
# moddified for -in memory updates- by: https://gathering.tweakers.net/forum/find/poster/959099/messages
# extra mod by me.
 
# crappy hack that seems to keep YouTube ads to a minumum.
# over two hours of Peppa Pig and no ads. Taking one for the team...
# grub@grub.net v0.11, SD Write tweak revision 2

# Change forceIPv4 to the real IP from an nslookup of a
# googlevideo hostname so you get something in your
# geographical region. You can find one in your
# Pi-hole's query logs.
# They will look something like this:
#     r6---sn-ni5f-tfbl.googlevideo.com
 
# as root: run this once then run "pihole restartdns"
# You can cron this for auto-updating of the host file.
# Mine fires every minute:
# * * * * * /home/grub/bin/youtube.update.sh 2>&1

 
#edit this to a real ip from ***.googlevideo.com
forceIPv4="123.456.789.999"
 
# nothing below here should need changing, except logging (line #51)
 
#use pihole v5 custom list ( "local dns records" in UI )
ytHosts="/etc/pihole/custom.list"

piLogs="/var/log/pihole.log"
 
#-- preload part

ytpreload="/etc/YTpreload.txt" 
workFile=$(mktemp)
dbFile="/etc/pihole/pihole-FTL.db"

if [ ! -f $ytpreload ]; then
	echo "preload done" > $ytpreload
    touch $ytHosts  
	
#fill ythosts file with contents of pihole db (slower but more hits)
cp $ytHosts $workFile
sqlite3 $dbFile "SELECT domain FROM queries WHERE domain LIKE '%sn-%.googlevideo.com' AND NOT domain LIKE '%--%';" \
    | awk -v fIP=$forceIP '{ print fIP, $1 }' >> $workFile

sort -u $workFile -o $workFile

if ! cmp $workFile $ytHosts; then
    echo "Previous number of hosts: " $(wc -l $ytHosts | awk '{ print$1 }')
    mv $workFile $ytHosts
    chmod 644 $ytHosts
    /usr/local/bin/pihole restartdns reload-lists
	/usr/local/bin/pihole restartdns reload
else
    rm -f $workFile
    echo "No new domains found."
fi

echo "Total number of entries: " $(wc -l $ytHosts | awk '{ print $1 }')	
	
fi
#--- end preload

#-- regular update [in memory]

ytEntries=$(wc -l $ytHosts)

for i in $(zgrep -e "r\d\.sn.*\.googlevideo\.com" $piLogs | awk '{ print $6 }')
do
   if [ $(grep -c "$i" $ytHosts) == 0 ]; then 
      # Add line to ytHosts
      echo $forceIPv4 $i >> $ytHosts
   fi
done
 
if [ "$ytEntries" != "$(wc -l $ytHosts)" ]; then
    /usr/local/bin/pihole restartdns reload-lists
	/usr/local/bin/pihole restartdns reload
#	 logger "youtube.update.sh: File updated to $(wc -l $ytHosts)" # uncomment if needed
fi

exit
