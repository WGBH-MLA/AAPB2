#!/bin/bash
# foo4thought was here

function usage {
echo 
echo "# usage: $(basename "$0") '/path/to/some/file.vtt'"
echo 
echo '# emits JSON to STDOUT' ;
echo 
}

function smpte2secs {
   tcode=$(echo $1 | tr -dC '[0-9]:;\.') ;
   while [ "$(echo $tcode | tr -s ':' ' ' | wc -w | awk '{print $1}')" -lt 3 ];
   do 
	   tcode="0:$tcode";
   done
   echo "$tcode"':0:0:0:0' | tr -s ':;' ' ' | awk '{print "scale=2;"$1" * 3600 + "$2" * 60 + "$3" + ("$4"/30)"}' | bc
}

if [ "$#" != 1 -o ! -f "$1" -o "$(basename "$1" | sed 's#^.*\.##g')" != 'vtt' ] ;
then 
	usage >&2;
	exit ;
fi

IFS=$'\n\b';
guid=$(basename "$1" .vtt);
printf %s '{"id":"'$guid'","language":"en-US","parts":[' ;
datatext=$(cat "$1" | grep -A2 '^[[:digit:]]*$' |  sed 's#^--$#\|#1;s#"#\\&#g;s#-->#'$'\t''#1' | tr -s '\n' '\t' | tr '|' '\n' | cut -f2-5);
if [ -z "$(echo "$datatext" | cut -f4 | grep '[[:alnum:]]')" ];
then
	datatext=$(echo "$datatext" | cat -n);
fi 
for i in $(echo "$datatext");
do 
	spid=$(echo $i | cut -f1);
	stime=$(smpte2secs "$(echo $i | cut -f2)");
	etime=$(smpte2secs "$(echo $i | cut -f3)");
	text=$(echo $i | cut -f4);
	echo '{"start_time": "'$stime'","end_time": "'$etime'","text": "'$text'","speaker_id": '$spid'},';
done | tr -d '\n' | sed 's#,$#\]\}#1' 
unset IFS ;
