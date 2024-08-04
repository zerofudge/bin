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
#       just use the '-help' argument.
#
# NO NEED TO EDIT THIS FILE FOR CONFIGURATION PURPOSES!

require 5.002;
use strict;
use File::Basename;


my $dir                 = '~/.headlines/';
my $WM                  = 'Gnome';
my $fdir                = '~/.gnome/apps';
my $command             = basename($0);
my $version             = '1.0';
my $no_new_window       = 0;
my $nspath              = 'netscape';
my $exec;
my $rv;
my $dmask = 0777 & ~umask();
my @MenuFiles;


###########################################
#  Procs
###########################################
    
sub XML_Parse {
    my ($line,$tline,$tmp,$title,$link) = '' x 5;


    my $DIR = $_[0];

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

    ## Create Menu Dir
    mkdir($DIR,$dmask);

    ## Create the Menu .dir file
    open(TMP, "> $DIR/.directory") || die "Couldn't open $DIR./directory\n";
    print(TMP '[Desktop Entry]' . "\n"
	. 'Name=' . $header . "\n"
	. 'Comment=' . $header . "\n"
	. 'Icon=gnome-news.png' . "\n"
	. 'Type=Directory' . "\n"
    );
    close(TMP);


    my @records = split(/<item>/i, $line);
    # remove the first entry, as it will be crap.
    shift(@records);

    my $idx=1;
    foreach my $entry (@records) {
	my $index;
        my @tmp = split(/<\/item>/i, $entry);
        $title = $tmp[0];
        $link = $tmp[0];
        $title =~ s/.*<title>(.+?)<\/title>.*/$1/is;
        $title =~ s/"/'/g;
        $link =~ s/.*<link>(.+?)<\/link>.*/$1/is;

        ## Create the Menu File
        if ($idx < 10) {
	    $index = '0' . $idx;
        } else {
	    $index = $idx;
	}
        $idx++;

	my $file = $DIR . '/' . $index . '.desktop';
        open(FILE1, "> $file") || die "Couldn't open $file for writing.\n";;
	print(FILE1 '[Desktop Entry]' . "\n"
	    . 'Name=' . $title . "\n"
	);
 
        if (defined($exec)) {
            print FILE1 qq{Exec=$exec '$link'\n};
        } else {
            $link = &NSEscape($link);
            if ($no_new_window) {
                print FILE1 qq{Exec=$nspath -noraise -remote 'openURL($link)' || $nspath '$link'\n};
            } else {
                print FILE1 qq{Exec=$nspath -noraise -remote 'openURL($link, new-window)' || $nspath '$link'\n};
            }
        }
        print(FILE1 'Type=URL' . "\n");
        close FILE1;
    }
    
    $/ = $oldlineseparator;
}

sub NSEscape {
    # Bad list: ,

    my $line = $_[0];
    $line =~ s/\,/%2c/g;
    return $line;
}

sub Nuke {

    my $name = $_[0];
    if ( -d $name ) {
        opendir(DIR,"$name") || die "Error: $name not readable.";
        my $myfile;
        my @Files = readdir(DIR);
        foreach my $myfile (@Files) {
            if ($myfile ne "." && $myfile ne "..") {
	        &Nuke("$name/$myfile");
            }
        }
        closedir(DIR);
        rmdir($name) || die "Couldn't remove dir: $name";
    } else {
	unlink($name) || die "Couldn't unlink $name\n";
    }


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
-fdir   directory       Specify the new MenuDir to write. 
                        (default is $fdir)
-nspath path/file       Specify the path to Netscape (the default)
-n                      Prevent Netscape from opening the link in
                        a new window. (default is new window)
-exec   command         Alternative Browser/HTTP Viewer
                        (must accept url as only argument.)
END

        exit 0;
    } elsif ($ARGV[$i] eq '-fdir') {
        if (!defined($ARGV[$i + 1])) {
            print "Error: -fdir requires an argument.\n";
            exit();
        } else {
            $i++;
            $fdir = $ARGV[$i];
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



@tmp = glob($fdir);

if ($tmp[0]) {
    $fdir = $tmp[0];
} else {
    print STDERR "Can't understand $fdir.\n";
}

### Verify/Create Toplevel dir.
if (! -d $fdir ) {
    $rv = mkdir($fdir,$dmask);
    if (!$rv) {
        die "Failed to create dir: $fdir: $!\n";
    } 
}



### Create the Temp Directory 
my $tdir = $fdir . '/.tmp';

if ( -d $tdir) {
    &Nuke($tdir);	
}

# create directory ie: .tmp/
$rv = mkdir($tdir,$dmask);
if (!$rv) {
    die "Failed to create dir: $tdir: $!\n";
} 
#Create .directory file.
open(TMP, "> $tdir/.directory") || die "Couldn't open $tdir/.directory\n";
print(TMP '[Desktop Entry]' . "\n"
    . 'Name=WMHeadlines' . "\n"
    . 'Comment=News without the hassle.' . "\n"
    . 'Icon=gnome-news.png' . "\n"
    . 'Type=Directory' . "\n"
);
close(TMP);



#Arrange files alphabettically/numerically
@MenuFiles = sort(@MenuFiles);

foreach my $fname (@MenuFiles) {
    open(XML, "< $fname") || die "Couldn't open $fname for reading.";
    $fname =~ s/^.+\/([^\/]+)$/$1/;
    my $DIR = $tdir . '/' . $fname;

    ## Create the Menu Dir.
    my @tmp = glob($DIR);
    if ($tmp[0]) {
        $DIR = $tmp[0];
    } else {
        print STDERR "Can't understand $DIR.\n";
	exit;
    }
        
    &XML_Parse($DIR);

    close(XML);
}

## Mover Old WMHeadlines Dir aside.
$fdir = $fdir . '/WMHeadlines';
my $otdir = $fdir . '.old';

if ( -d $otdir ) {
    #Nuke the old instance of it.
    &Nuke($otdir);
}

if (-d $fdir) {
    $rv = system('mv', $fdir, $otdir);
    $rv = $rv / 256;
    if ($rv) {
        die "couldn't move $otdir to $fdir\n";
    }
}


### Move Temp to WMHeadlines ######
$rv = system('mv', $tdir ,$fdir);
$rv = $rv / 256;
if ($rv) {
    die "couldn't move $tdir to $fdir\n";
}

### Remove old WMHeadlines Dir.
if ( -d $otdir) {
    &Nuke($otdir);
}

exit 0;

