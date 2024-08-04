#!/usr/bin/perl

# Netscape launcher for WMHeadlines v1.0, Written by Kenneth Persinger
# http://www.shutdown.com/~lestat/   --  lestat@iglou.com
#
# See Credits.txt for all the people who made this possible.
#
# this code is licensed under the GPL version 2.
# this code is Copyright (C) 2000 by Kenn Persinger
# this code comes with ABSOLUTELY NO WARRANTY.

#
# Script for allowing a user to open a Netscape  on the current desktop
# without opening a new instance, and w/o using the file/open/new
# navigator option, which require to to switch desktops.
#

## Pre defines ########################
my $URL 	= 'about:blank';
my $NETSCAPE 	= 'firefox';
my $GREP	= 'grep';
my $PS		= 'ps';
my $PSARGS	= 'x';
my $HOME	= $ENV{HOME};
my $LOCK	= (glob('~/.netscape/lock'))[0];

if (defined($ENV{NETSCAPEHOME})) {
    $URL = $ENV{NETSCAPEHOME};
} 

if (defined($ENV{NETSCAPE})) {
    $NETSCAPE = $ENV{NETSCAPE};
} 

#######################################


## Procedures #########################
sub Escape {
    # Bad list: ;,
    my $line = $_[0];
    $line =~ s/,/%2c/g;
    return $line;
}


#######################################



## Main ###############################

# Check for an arg.
if (scalar(@ARGV)) {
    $URL = $ARGV[0];
}

# Escape Url
$URL = &Escape($URL);


# Fork off a new process.
my $v = fork();
if ($v != 0) {
    exit;
}

# Check for another instance.
# This isn't perfect.. but pretty darn close.
if (-l $LOCK) {
    my $pid = (split(/:/,readlink($LOCK)))[1];
    my $rv = system("kill -0 $pid 2>&1 > /dev/null");
    $rv = $rv / 256; 
    if (!$rv) {
	# Remote Instance
	exec($NETSCAPE, '-noraise', '-remote', "openURL($URL,new-window)");
    } else {
	# New Instance
	exec("$NETSCAPE", "$URL");
    }
} else {
    # New Instance.
	exec("$NETSCAPE", "$URL");
}




#######################################

