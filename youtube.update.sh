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
 
piLogs="/var/log/pihole.log"

#user pihole v5 custom list ( "local dns records" in UI )
ytHosts="/etc/pihole/custom.list"
 
dnsmasqFile="/etc/dnsmasq.d/99-youtube.grublets.conf"
 
if [ ! -f $dnsmasqFile ]; then
    echo "addn-hosts=$ytHosts" > $dnsmasqFile
    touch $ytHosts
    piLogs="$piLogs*" # preload with results from all logs
    echo "Setup complete! Execute 'pihole restartdns' as root."
    echo "cron the script to run every minute or so for updates."
fi
 
ytEntries=$(wc -l $ytHosts)

#changed regex
for i in $(zgrep -e "r\d.*\.googlevideo\.com" $piLogs | awk '{ print $6 }')
do
   if [ $(grep -c "$i" $ytHosts) == 0 ]; then 
      # Add line to ytHosts
      echo $forceIPv4 $i >> $ytHosts
   fi
done
 
if [ "$ytEntries" != "$(wc -l $ytHosts)" ]; then
#	 logger "youtube.update.sh: File updated to $(wc -l $ytHosts)" # uncomment if needed
   /usr/local/bin/pihole restartdns reload
fi
 
exit
