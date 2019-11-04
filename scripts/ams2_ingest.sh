#!/bin/sh
SAVEIFS=$IFS
IFS=$'\n'

echo "please submit the folder containing files to ingest"
read ingest

ingest=$(printf %s "$ingest" | cut -c1-$[$(printf %s "$ingest" | wc -c | awk '{print $1}')-1])

echo "please submit the folder where you want to write your .zip for ingest"
read destination

destination=$(printf %s "$destination" | cut -c1-$[$(printf %s "$destination" | wc -c | awk '{print $1}')-1])

echo "drag and drop the ingest spreadsheet"
read ref

ref=$(printf %s "$ref" | cut -c1-$[$(printf %s "$ref" | wc -c | awk '{print $1}')-1])

echo "What is the instantiationGeneration of these files? enter Master or Proxy"
read generation

echo "What is the holding organization of these files?"
read org

echo "What is the AAPB Preservation LTO that these files will be stored on?"
read lto

echo "What is the AAPB Preservation Disk that these files will be stored on?"
read disk

mkdir $destination/$org 

zipdir=$( echo $destination/$org )

echo "DigitalInstantiation.filename,Asset.id,DigitalInstantiation.generations,DigitalInstantiation.holding_organization,DigitalInstantition.aapb_preservation_lto,DigitalInstantition.aapb_preservation_disk,DigitalInstantiation.md5" > $zipdir/manifest.csv
for f in $(find $ingest -type f); do
	filename="${f#"$ingest/"}"
	if grep ${filename}, $ref
	then
		assetid=$( grep ${filename}, $ref | cut -d , -f 2 )
		mediainfo --Output=PBCore2 $f > $zipdir/${filename}.mediainfo.xml
		md5=$( md5 $f | rev | cut -d ' ' -f 1 | rev )
		echo "${filename}.mediainfo.xml,${assetid},${generation},${org},${lto},${disk},${md5}" >> $zipdir/manifest.csv
	else
		:
	fi
done

zip -r $zipdir.zip $zipdir
