#!/bin/bash

## define variables

IFS=$'\n';

echo "Drag and drop the folder containing the AAPB proxies to concatenate"
read dir

dir=$(printf %s "$dir" | cut -c1-$[$(printf %s "$dir" | wc -c | awk '{print $1}')-1])


cd $dir

for file in $(find . -type f -name "*_01*"); do 
	guid=$(echo $file | cut -d '/' -f 2 | cut -d '_' -f 1)
	suffix=$(echo $file | cut -d '.' -f 3)
	if test -f "$guid.$suffix"
	then
		echo "$guid.$suffix" exists
	else
		ls | grep $guid > list.txt
		list=$(find . -type f -name *.txt)
		filename=$list
		while read f; do
			echo "file '$f'" >> concat.txt
		done < $filename
		cat concat.txt
		docker run -v $(pwd):$(pwd) -w $(pwd) linuxserver/ffmpeg -f concat -i concat.txt -c copy "$guid.$suffix"
		rm concat.txt
	fi
done
