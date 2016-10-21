#!/bin/sh
SAVEIFS=$IFS
IFS=$'\n'

ingest="/Volumes/New_AAPB_Collections/Voegeli_Files"
bags="/Volumes/New_AAPB_Collections/Voegeli_Bags"

for d in $(find $ingest -type d -maxdepth 1 -mindepth 1); do
	guid=$(echo $d | cut -d / -f 5)
	echo $guid
	mkdir $bags/$guid && mkdir $bags/$guid/master && mkdir $bags/$guid/proxy
	for f in $(find $d -type f -path '*master*'); do
		echo $f
		file=$( echo $f | cut -d '/' -f 7 )
		echo $file
		mediainfo --Language=Raw --Output=XML $f > $bags/$guid/master/${file}.mediainfo.xml
	done
	for p in $(find $d -type f -path '*proxy*'); do
		echo $p
		proxy=$( echo $p | cut -d '/' -f 7 )
		mediainfo --Language=Raw --Output=XML $p > $bags/$guid/proxy/${proxy}.mediainfo.xml
	done
	/Users/rebecca_fraimow/bagit-python/bagit.py $bags/$guid
	cd $bags
	zip -r ${guid}-sparse.zip $guid
	find . -type d -maxdepth 1 -mindepth 1 -not -name "*.zip" -exec rm -R {} \;
	
done

IFS=$SAVEIFS
