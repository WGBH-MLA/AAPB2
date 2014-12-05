#!/bin/sh
# This will take a directory full of .mp4 files and grab a jpg thumbnail from the middle of each .mp4 file and save them in a subdirectory.
# Note, you must have ffmpeg/ffprobe installed on the machine.

# open terminal
# cd source folder
# create new folder called "jpg" within source folder
# copy and paste code below in terminal window

OLDIFS=$IFS;IFS=`echo -en '\n\b'`;for f in *.mp4; do medianSecs=`ffprobe $f 2>&1 | grep -i duration | tr -C '[0-9]' ' ' | awk '{print "("$1"\*3600 + "$2"\*60 + "$3")/2"}' | bc `; ffmpeg -i $f -ss "$medianSecs" -f image2 -vframes 1 "jpg/${f%.mp4}.jpg"; done;IFS=$OLDIFS

# press return
