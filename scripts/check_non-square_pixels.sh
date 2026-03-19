#!/bin/bash
# check_non-square_pixels.sh
#
# Checks each video file in the current directory using MediaInfo.
# If the file has non-square pixels (pixel aspect ration != 1.000), then
# the name of that file is output.

# Enable nullglob so patterns with no matches are ignored
shopt -s nullglob

# Iterate over each file in the current directory
for file in *.{mp4,MP4,mov,MOV,mkv,MKV}; do
    # Run MediaInfo and look for the "Pixel aspect ratio" line
    pixel_aspect_ratio=$(mediainfo -f "$file" | grep "Pixel aspect ratio" | awk -F ': ' '{print $2}')
    
    # Check if the pixel aspect ratio exists and is not "1.000"
    if [[ -n $pixel_aspect_ratio && "$pixel_aspect_ratio" != "1.000" ]]; then
        # Print the filename if the aspect ratio is not 1.000
        echo "$file"
    fi
done
