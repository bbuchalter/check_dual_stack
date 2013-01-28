Copyright 2013, Brian Buchalter, http://www.endpoint.com - Licensed under GPLv2

SUMMARY
Given a hostname and Nagios check command, execute check command
for each A and AAAA DNS record, replacing HOSTNAME with the IP.
Returns most severe exit code.

USAGE
./check_dual_stack.pl -H my.host.com -C "/usr/lib64/nagios/plugins/check_ping" -A "-t 60 -H HOSTNAME -w 3000.0,80% -c 5000.0,100% -p 3" 

OPTIONS
-H      Hostname to resolve A and AAAA DNS records
-C      Nagios check command to execute
-A      Arguments for Nagios check command, must include HOSTNAME (not $HOSTNAME$)
-d      Display debugging information, command executed, exit code returned
--help      shows this message
--version   shows version information

