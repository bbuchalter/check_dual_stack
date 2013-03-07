SUMMARY
=======
Given a hostname and Nagios check command, execute check command
for each A and AAAA DNS record, replacing HOSTNAME with the IP.
Returns most severe exit code.


USAGE
=====
```
./check_dual_stack.pl -H my.host.com -C "/usr/lib64/nagios/plugins/check_ping" -A "-t 60 -H HOSTNAME -w 3000.0,80% -c 5000.0,100% -p 3" 
```

OPTIONS
=======
-H      Hostname to resolve A and AAAA DNS records
-C      Nagios check command to execute
-A      Arguments for Nagios check command, must include HOSTNAME (not $HOSTNAME$)
-d      Display debugging information, command executed, exit code returned (optional)
--help      shows this message
--version   shows version information


SAMPLE NAGIOS SERVICE DEFINITION
================================
Let's assume you've got a check_ping command defined as follows:
```
define command{
        command_name    check_ping
        command_line    $USER1$/check_ping -t 30 -H $HOSTADDRESS$ -w $ARG1$ -c $ARG2$ -p 5 -4
}
```

$USER1$ represents the absolute path to where your Nagios plugins are stored.

To use this check with check_dual_stack you'd ADD the following service definition:
```
define command{
        command_name    check_ping_dual_stack
        command_line    $USER1$/check_dual_stack.pl -H $HOSTADDRESS$ -C "$USER1$/check_ping" -A "-t 30 -H HOSTNAME -w $ARG1$ -c $ARG2$ -p 5" 
}
```

*NOTE:* The biggest change here is that you are REMOVING $HOSTADDRESS$ in the A argument, and replacing it with HOSTNAME. This is REQUIRED.


Here's another example:
```
define command{
        command_name    check_ssh
        command_line    $USER1$/check_ssh -t 30 $ARG1$ $HOSTADDRESS$
}   

define command{
        command_name    check_ssh_dual_stack
        command_line    $USER1$/check_dual_stack.pl -H $HOSTADDRESS$ -C "$USER1$/check_ssh" -A "-t 30 $ARG1$ HOSTNAME"
}   
```


Copyright 2013, Brian Buchalter, http://www.endpoint.com - Licensed under GPLv2
