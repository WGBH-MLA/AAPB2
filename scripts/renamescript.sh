#!/bin/sh
SAVEIFS=$IFS
IFS=$'\n'

read -p "drag and drop the spreadsheet containing CPB GUIDs:	
" p1;
ref=$(echo $p1 | tr -d ' ')

file=$( find . \( ! -regex '.*/\..*' \) ! -path . -type f )
for file in $file; do
	origname=$( echo $file | cut -d '/' -f 2 )
	echo $originame
	ID=$( echo $origname | cut -d '.' -f 1 )
	echo $ID
	cpb=$( grep ${ID} $ref | cut -d , -f 1 )
	echo $cpb
	newname=${cpb}.mp4
	echo $newname
	mv $file ./$newname
done
