#!/usr/bin/perl -w

# WMHeadlines WM-Specific Front-Ends  v1.0, Written by Kenneth Persinger
# http://www.shutdown.com/~lestat/   --  lestat@iglou.com
#
# See Credits.txt for all the people who made this possible.
#
# this code is licensed under the GPL version 2.
# this code is Copyright (C) 2000 by Kenn Persinger
# this code comes with ABSOLUTELY NO WARRANTY.
#
#    All options are available from the command line.
# 	just use the '-help' argument.
#
# NO NEED TO EDIT THIS FILE FOR CONFIGURATION PURPOSES!

require 5.002;
use strict;
use File::Basename;


my $dir  		= '~/.headlines/';
my $WM			= 'WindowMaker';
my $file 		= '~/.MyHeadlines.menu';
my $command 		= basename($0);
my $version	 	= '1.0';
my $no_new_window	= 0;
my $nspath		= 'netscape';
my $exec;
my @MenuFiles;


###########################################
#  Procs
###########################################


sub XML_Parse {
    my ($line,$tline,$tmp,$title,$link) = '' x 5;

    my $oldlineseparator = $/;
    $/ = undef;
    $line = <XML>;

    if ($line eq '') {
        return;
    }

    $line =~ s/\n//gs;
    $line =~ s/\r//gs;

    my $header = $line;
    $header =~ s/.*<channel>(.+?)<\/channel>.*/$1/is;
    $header =~ s/.*<title>(.+?)<\/title>.*/$1/is;

    #print the menu header
    print FILE1 qq{"$header" MENU\n};

    my @records = split(/<item>/i, $line);
    # remove the first entry, as it will be crap.
    shift(@records);

    foreach my $entry (@records) {
        my @tmp = split(/<\/item>/i, $entry);
        $title = $tmp[0];
        $link = $tmp[0];
        $title =~ s/.*<title>(.+?)<\/title>.*/$1/is;
        $title =~ s/"/'/g;
        $link =~ s/.*<link>(.+?)<\/link>.*/$1/is;
       
        if (defined($exec)) {
            print FILE1 qq{"$title" EXEC $exec '$link'\n};
        } else {
	    $link = &NSEscape($link);
	    if ($no_new_window) {
                print FILE1 qq{"$title" EXEC $nspath -noraise -remote 'openURL($link)' || $nspath '$link'\n};
            } else {
                print FILE1 qq{"$title" EXEC $nspath -noraise -remote 'openURL($link, new-window)' || $nspath '$link'\n};
	    }
        }
    }
    
    #print the footer
    print FILE1 qq{"$header" END\n};

    $/ = $oldlineseparator;
}


sub NSEscape {
    # Bad list: ,
    # only need to escape , b/c of Netscape 
    # the '' quoting handles everything else.
    my $line = $_[0];
    $line =~ s/\,/%2c/g;
    return $line;
}







##########################################
#  Main 
##########################################

### Arg Checking ###
my $i;
for ($i = 0; $i < scalar(@ARGV); $i++) {
    if ($ARGV[$i] =~ /-h(?:elp)?$/i) {
        print << "END";
WMHeadlines $WM Front-end Version $version 
Written by Kenneth Persinger (lestat\@iglou.com)

Usage: $command [options]
Options                 Description
-dir    directory       Specify the directory where the headlines are.
                        (default is $dir)
-file   filename        Specify the new menufile to write. 
                        (default is $file)
-nspath path/file	Specify the path to Netscape (the default)
-n			Prevent Netscape from opening the link in
			a new window. (default is new window)
-exec	command		Alternative Browser/HTTP Viewer
			(must accept url as only argument.)
END

        exit 0;
    } elsif ($ARGV[$i] eq '-file') {
        if (!defined($ARGV[$i + 1])) {
            print "Error: -file requires an argument.\n";
            exit();
        } else {
	    $i++;
            $file = $ARGV[$i];
        }
    } elsif ($ARGV[$i] eq '-exec') {
        if (!defined($ARGV[$i + 1])) {
            print "Error: -exec requires an argument.\n";
            exit();
        } else {
	    $i++;
            $exec = $ARGV[$i];
        }
    } elsif($ARGV[$i] eq '-nspath') {
        if (!defined($ARGV[$i + 1]) || ($ARGV[$i + 1] !~ /^\//)) {
            print "Please use '-nspath /path/to/netscape'\n";
            exit();
        } else {
	    $i++;
            $nspath = $ARGV[$i];
        }
    } elsif ($ARGV[$i] eq '-n') {
	$no_new_window = 1;
    } elsif ($ARGV[$i] eq '-dir') {
        if (!defined($ARGV[$i + 1])) {
            print "Error: -dir requires an argument.\n";
            exit();
        } else {
	    $i++;
            $dir = $ARGV[$i];
        }
    } 
}


### Open Headlines Dir
my @tmp = glob($dir);

if ($tmp[0]) {
    $dir = $tmp[0];
} else {
    print STDERR "Can't understand $dir.\n";
}

opendir(CDIR,"$dir") || die "Error: $dir not readable/does not exist.\n";

my $myfile;
while (defined($myfile = readdir(CDIR))) {
    if ($myfile ne "." && $myfile ne "..") {
        $myfile = $dir . '/' . $myfile;
        push(@MenuFiles,$myfile);
    }
}
if (length(@MenuFiles) == 0) {
    die "Error: no files found in $dir";
}           
closedir(CDIR);


### Open output file.
@tmp = glob($file);
if ($tmp[0]) {
    $file = $tmp[0];
} else {
    print STDERR "Can't understand $file.\n";
}

open(FILE1,"> $file") || die "Couldn't open $file for writing.";

#Arrange files alphabettically/numerically
@MenuFiles = sort(@MenuFiles);

### Print Header
print FILE1 qq{"WMHeadlines" MENU\n};
foreach my $fname (@MenuFiles) {
    open(XML, "< $fname") || die "Couldn't open $fname for reading.";
    my $oldlineseparator = $/;
    &XML_Parse;
    close(XML);
}

### Print Footer 
print FILE1 qq{"WMHeadlines" END\n};
close(FILE1);
exit 0;

########
# End  #
########
