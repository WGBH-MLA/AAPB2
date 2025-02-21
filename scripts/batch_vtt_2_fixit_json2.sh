#!/bin/bash -l

echo "type path to folder containing VTT files or drag/drop it; then press enter" && read inputFolderPath ;
echo "type path to folder to receive JSON files or drag/drop it; then press enter" && read outputFolderPath ; 
echo "type path to file 'vtt_2_fixit_json2.sh' or drag/drop it; then press enter" && read scriptFilePath ;
# sanity check on userland data here 
if [ -d "$inputFolderPath" -a ! -f "$outputFolderPath" -a -e "$scriptFilePath" -a -x "$scriptFilePath" ] ; 
then 
  origDirPath=$(pwd -P) ;
  mkdir -p "$outputFolderPath" ;
  cd "$outputFolderPath" ;
  outputFolderPath=$(pwd -P)/ ;
  cd "$inputFolderPath" ;
  IFS=$'\n\b' ;
  for vttFile in $(ls -1 *.[Vv][Tt][Tt]);
  do 
    "$scriptFilePath" "$vttFile" > "$outputFolderPath""$(echo "$vttFile" | sed 's#\.[Vv][Tt][Tt].*$#-transcript.json#1' )" 2>> "$outputFolderPath""vtt_2_fixit_json2_errors.txt" ;
  done ;
  cd "$origDirPath" ; 
fi ;
unset "$IFS" ; 
open "$outputFolderPath" ;
