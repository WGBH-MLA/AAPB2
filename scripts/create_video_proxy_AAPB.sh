#!/bin/bash
# run with two args:  first is input directory path and second is output directory path
function usage()
{
	echo 'usage:  '$(basename $0)': /path/to/input/ /path/to/output/'
	echo '--';
	echo 'this script explores the input file system and selectively makes proxy versions of its media files in the output file system';
	echo 'NOTE: both arguments must be usable directories';
	exit;
}

# sanity checks
if [ "$#" -ne 2 ];
then
	echo "ERROR:  two arguments are required";
	usage;
fi;

if [ ! -d "$1" -o ! -r "$1" ];
then
	echo "ERROR:  $1 is not a readable directory";
	usage;
fi;

if [ ! -d "$2" -o ! -w "$2" ];
then
	echo "ERROR:  $2 is not a writable directory";
	usage;
fi;

inDir="$1";
outDir="$2";

cd "$inDir";

OLDIFS=$IFS;
IFS=`echo -en '\n\b'`;

for i in `find . -type f | grep -i '\(mp4\|mov\|mts\|vob\|mpg\|webm\|mkv\|mxf\|m4v\|raw\|avi\)$'` ;
do 
	newDir=`dirname "$i"`; # modify this if you want to include the basename of the input argument directory
	mkdir -p "$outDir/$newDir";
	if mediainfo "$i" | grep '16:9'; then
		ffmpeg -i "$i" -vcodec libx264 -pix_fmt yuv420p -b:v 711k -s 640:360 -acodec libfdk_aac -b:a 128k "$outDir/$newDir/$(basename $i)".mp4;
	else 
		ffmpeg -i "$i" -vcodec libx264 -pix_fmt yuv420p -b:v 711k -s 480:360 -acodec libfdk_aac -b:a 128k "$outDir/$newDir/$(basename $i)".mp4;
	fi
done ;
IFS=$OLDIFS
