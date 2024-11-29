#!/usr/bin/bash

#Cron Entry
#Check motion
#* * * * * sudo /usr/bin/bash $INSTALLDIR/watchdog.sh > /dev/null

UP=$(tail -n 5 /var/log/motion/motion.log | grep "ERR" | wc -l)

if (( $UP > 0 )) ;
    then
    systemctl restart motion
    echo "$(date) - Restarting Motion" > /tmp/motion_watchdong.log
    fi
