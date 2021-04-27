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

for i in `find . -type f | grep -i '\(mp3\|m4a\|wmv\|aif\|aac\|aiff\|wma\|wav\)$'` ;
do 
	newDir=`dirname "$i"`; # modify this if you want to include the basename of the input argument directory
	mkdir -p "$inDir/proxies";
	docker run -v $(pwd):$(pwd) -w $(pwd) jrottenberg/ffmpeg -i "$i" -acodec libmp3lame -ab 192k "proxies/$(basename $i)".mp3;
	
done ;
cd
find "$inDir/proxies" -type f -exec mv {} "$outDir" \;
rm -r "$inDir/proxies"
IFS=$OLDIFS
