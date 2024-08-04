#!/bin/tcsh -f

# v0.02
# example script for encoding an entire CD to mp3 files
# tested under Red Hat Linux 6.0
#
# (C) 1999 Conrad Sanderson
# This script is released under the GPL v2 license 
# ( see http://www.gnu.org )
#
# usage:  encode_cd.sh track_list_file destination_directory
#
# - track_list_file contains the names of all tracks, in order.
#   any tracks named "skip" will be skipped
#
# - destination_directory is the name of the directory where to put
#   the resulting mp3 files.  it will be created if it doesn't exist
#
# - resultant mp3 files will have track numbers in front of their names
#   and all spaces converted to underscores
#
#
# requirements:
#
# - your /tmp directory must have enough room to hold a temporary wav file
#   (usually about 50 megs) and a temporary mp3 file (about 5 megs)
#
# - your destination directory must be able to hold all the mp3 files
#   (50 to 100 megs)
#
# - cdparanoia track ripper, http://www.xiph.org/paranoia/
#   you can modify the script to use cdda2wav instead if necessary )
#
# - notlame mp3 encoder ( http://hive.me.gu.edu.au/not_lame/ )
#

set file=(`which cdparanoia`)
if (! -x $file[1]) then
	echo "error: cdparanoia is not installed or not in your path"
	exit -1
endif

set file=(`which notlame`)
if (! -x $file[1]) then
	echo "error: notlame is not installed or not in your path"
	exit -1
endif


set num=$#
set tracklist=$1
set dir=$2

if ( $num != 2 ) then
        echo "usage: $0 track_list_file destination_directory"
        exit -1
endif

if (! -e $tracklist) then
	echo "error: $1 doesn't exist"
	exit -1
endif


if (! -d $dir) then

	if(-e $dir) then
		echo "error: couldn't create $dir directory - file with the same name exists"
		exit -1
	endif
	
	mkdir $dir
	
endif


# needed later on
set p=p
set u=_
set skip="skip"
set tmpwav=/tmp/$$.tmp.wav
set tmpmp3=/tmp/$$.tmp.mp3
set tmplist=/tmp/tmp.$0:t.$$

onintr cleanup

# clean up the track list
# remove blank lines, trailing white space
# replace spaces with underscores 
# remove characters like & * @
# (i found a bug in GNU sed 3.02 while removing leading white spaces)

sed '/^$/d;s/[ \t]*$//;s/ /_/g;s/*//g;s/&//g;s/@//g' $1 >! $tmplist


# see if we have any track names
if( -z $tmplist ) then
	echo "error: $1 doesn't have any track names"
	exit -1
endif


set lines=(`sed -n '$=' $tmplist`)


set line=1

while ( $line <= $lines )
        
	set name=(`sed -n $line$p $tmplist`)
	
	echo "-------------------------------"

	if ( $name == $skip ) then
		echo "skipping track $line ($name)"
	else
		echo "processing track $line ($name)"
		echo " "

		nice cdparanoia $line $tmpwav
		# nice cdda2wav -t $line $tmpwav

		if( -e $tmpwav ) then 
			if(! -z $tmpwav) then
				nice notlame $tmpwav $tmpmp3
				set h=(`printf "%02d" $line`)
				mv --force $tmpmp3 "$dir/$h$u$name.mp3"
			endif
		endif
	endif
	
	@ line++

end

cleanup:

rm -rf $tmpwav
rm -rf $tmpmp3
rm -rf $tmplist
