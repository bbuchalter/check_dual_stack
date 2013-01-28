#!/usr/bin/env perl

use warnings;
use strict;
use Getopt::Std;
use Net::DNS;


my $plugin_name = "Nagios check_dual_stack";
my $VERSION = "1.00";


# getopt module config
$Getopt::Std::STANDARD_HELP_VERSION = 1;


# nagios exit codes
use constant EXIT_OK            => 0;
use constant EXIT_WARNING       => 1;
use constant EXIT_CRITICAL      => 2;
use constant EXIT_UNKNOWN       => 3;
# set default state
my $status = EXIT_UNKNOWN;


#parse arguments
my %opts;
getopts('H:C:A:d', \%opts);
check_usage();

my $hostname = $opts{H};
my $cmd = $opts{C};
my $cmd_args = $opts{A};
my $debug = $opts{d};
my @ipv6 = get_addresses($hostname, "AAAA");
my @ipv4 = get_addresses($hostname, "A");
my @addresses = (@ipv4,@ipv6);
my @exit_codes = qw();



foreach my $address (@addresses) {
    my($new_cmd) = parse_cmd($cmd, $cmd_args, $address);

    if($debug) { print "Executing $new_cmd\n"; }

    system($new_cmd);
    my($exit_code) = ($? >> 8);
    push(@exit_codes, $exit_code);

    if($debug) { print "Exit code: $exit_code\n"; }
}

# exit with most severe exit code
if ( grep { $_ eq EXIT_CRITICAL} @exit_codes ){
    exit EXIT_CRITICAL;
}
elsif ( grep { $_ eq EXIT_WARNING} @exit_codes ){
    exit EXIT_WARNING;
}
elsif ( grep { $_ eq EXIT_UNKNOWN} @exit_codes ){
    exit EXIT_UNKNOWN;
}
elsif (@exit_codes == grep { $_ eq EXIT_OK } @exit_codes) {
    # all equal EXIT_OK
    exit EXIT_OK;
}
else {
    exit EXIT_UNKNOWN;
}





# END MAIN, BEGIN SUBS
sub get_addresses {
    my ($hostname, $record_type) = @_;

    my @addresses;
    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search($hostname, $record_type);

    if ($query) {
        foreach my $rr ($query->answer) {
            push(@addresses, $rr->address);
        }
    } 
    else {
        warn "query failed: ", $res->errorstring, "\n";
    }
    
    return @addresses;    
}


sub HELP_MESSAGE {
        print <<EOHELP

SUMMARY
Given a hostname and Nagios check command, execute check command
for each A and AAAA DNS record, replacing HOSTNAME with the IP.
Returns most severe exit code.

USAGE
$0 -H my.host.com -C "/usr/lib64/nagios/plugins/check_ping" -A "-t 60 -H HOSTNAME -w 3000.0,80% -c 5000.0,100% -p 3" 

OPTIONS
-H      Hostname to resolve A and AAAA DNS records
-C      Nagios check command to execute
-A      Arguments for Nagios check command, must include HOSTNAME (not \$HOSTNAME\$)
-d      Display debugging information, command executed, exit code returned (optional)
--help      shows this message
--version   shows version information

EOHELP
;
}


sub VERSION_MESSAGE {
    print <<EOVM
$plugin_name v.$VERSION
Copyright 2013, Brian Buchalter, http://www.endpoint.com - Licensed under GPLv2
EOVM
;
}

sub check_usage {
    check_opts_defined();
    check_command_exists();
    check_command_has_hostname();
}

sub check_opts_defined {
    if (not(defined $opts{H}) or not(defined $opts{C}) or not(defined $opts{A})) {
        print "Missing required arguments\n";
        invalid_usage();
    }
}

sub check_command_exists {
    unless (substr($opts{C},0,1) eq "/") {
        print "Please use absolute paths to in the Nagios check command.\n";
        invalid_usage();
    }

    unless (-e $opts{C}) {
        print "Specified Nagios check command does not exist.\n";
        invalid_usage();
    }

    unless (-x $opts{C}) {
        print "Specified Nagios check command is not executable.\n";
        invalid_usage();
    }
}

sub check_command_has_hostname {
    if ( not($opts{A} =~ /HOSTNAME/) ) {
        print "A argument is missing HOSTNAME to interoplate IP addresses into\n";
        invalid_usage();
    }
}

sub invalid_usage {
    print "ERROR: INVALID USAGE\n";
    HELP_MESSAGE();
    exit EXIT_UNKNOWN;
}

sub parse_cmd {
    my($new_cmd, $cmd_opts, $address) = @_;

    # Assumes HOSTNAME will be passed in cmd for replacement with IP addresses
    # Nagios will substitue in a hardcoded host address, so we cannot wrap with $ (e.g. $HOSTNAME$)
    # in the passed command. I don't like this either...
    $cmd_opts =~ s/HOSTNAME/$address/g;

    # Assumes we don't want to specify -4 or -6 options, check_ping doesn't seem to need this
    # will check other plugins. Ignore whitespace on either side of those options.
    $cmd_opts =~ s/(\s|^)+-[46](\s|$)//g;

    return "$new_cmd $cmd_opts";
}