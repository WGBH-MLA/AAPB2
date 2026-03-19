#!/bin/bash
# correct_non-square_pixels.sh
#
# Checks and corrects (when possible) non-square pixels of 4x3 videos.
#
# Loops through each video file in the current directory and uses MediaInfo.
# If the file has non-square pixels (pixel aspect ration != 1.000), 
# then if the file has an aspect ratio of 4:3, runs ffmpeg to re-set aspect ratio.

# Enable nullglob so patterns with no matches are ignored
shopt -s nullglob

logfilename=non-square_corrected_$(date +"%Y-%m-%d_%H%M").log

# Iterate over each video file in the current directory
for f in *.{mp4,MP4,mov,MOV,mkv,MKV}; do
    # Run MediaInfo and look for the "Pixel aspect ratio" line
    pixel_aspect_ratio=$(mediainfo -f "$f" | grep "Pixel aspect ratio" | awk -F ': ' '{print $2}')
    
    # Check if the pixel aspect ratio exists and is not "1.000"
    if [[ -n $pixel_aspect_ratio && "$pixel_aspect_ratio" != "1.000" ]]; then
        
        # Get the display aspect ratio (expressed as a ratio, not a decimal value)
        display_aspect_ratio=$(mediainfo -f $f | grep "Display aspect ratio" | grep ":" | awk -F ': ' '/:/{if ($2 ~ /:/) {print $2; exit}}')
        # echo $display_aspect_ratio
        
        if [[ "$display_aspect_ratio" == "4:3" ]]; then
            ffmpeg -i $f -c copy -aspect 4:3 "${f%.*}"_4x3."${f##*.}"
            
            # replace the original file with the corrected file
            # (Comment out the following line if you don't want the originals overwritten.)
            mv "${f%.*}"_4x3."${f##*.}" $f

            # log the name of the file that was corrected
            echo $f >> $logfilename
            
        else
            echo "Skipping $f because display aspect ratio is not 4:3."
        fi
        
    else
        echo "Skipping $f because pixel aspect ratio is 1.000."
    fi
done
