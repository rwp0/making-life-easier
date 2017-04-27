#!/bin/bash

## emergency.sh
##
## This script is designed to help entry level techs quickly run some basic
## troubleshooting steps on a server when they notice things going awry. It
## is designed for simple CentOS7 systems running Nginx. The user will need
## sudo access to netstat to run the script.

echo -e "\n\nThis is going to restart some services, run some basic checks, and if all else fails restart the server.\n\n"

nginxRestart ()
{
sudo systemctl restart nginx
systemctl status nginx | grep running
[ $? -eq 1 ] && echo -e "restart failed, outputting log lines:\n"; sudo tail -25 /var/log/nginx/error.log; journalctl -xn;
}

touch $HOME/thiswillneverexist && rm -f $HOME/thiswillneverexist
[ $? -eq 0 ] && echo -e "Filesystem looks okay" || echo -e "Filesystem Check Failed - CRITICAL"

systemctl status nginx | grep running &>/dev/null
[ $? -eq 0 ] && echo -e "Web server process is running" || ( echo -e "Web server process not running, restarting now" && nginxRestart )

sudo netstat -plunt | egrep "0\.0\.0\.0:80.*LISTEN.*nginx" &>/dev/null
[ $? -eq 0 ] && echo -e "Web server process is listening on proper port" || ( echo -e "Web server process not listening, restarting now" && nginxRestart )

df / | tail -n +2 | awk '{ (if $4 > 40000) print}' &>/dev/null
[ $? -eq 1 ] && echo -e "No disk space issues" || echo -e "Disk space dangerously low"

echo "Checks have completed, are things still broken? (y or n). You will not see what you type, just press the letter and hit enter."
read -s ANSWER
[ $ANSWER == "y" ] && ( echo "Last resort is a complete server reboot. Server will shutdown right now. Please log in after 5 minutes to check on things again. Hit ctrl+c to cancel"; sleep 10; shutdown -r now ) || ( echo "Very good. Bye now."; exit 1; )
