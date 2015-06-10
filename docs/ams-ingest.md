Ingest into the AMS has been an ad-hoc process because each time we've needed to do something a little different. If we can identify a common thread, great, but until then, here are some notes.

Given a Muraszko-generated directory of unix-format text files containing tab-delimited data like this:
```
2015-02-19 10:31:39 -0500	cpb-aacip-17-00000qrv.h264.mp4	someLongString	{"id"=>"someReallyLongString", "name"=>"cpb-aacip-17-00000qrv.h264.mp4", "size"=>185277328, "createdBy"=>{"id"=>"someEvenLongerString", "name"=>"M Muraszko", "email"=>"m_muraszko@foo.bar"}, "createdOn"=>"2015-02-19T15:30:49.41Z", "thumbnailUrl"=>"https://foo.cloudfront.net/cifiles/someDirectoryString/early-thumbnail.jpg?Policy=absurdlyLongString", "proxyUrl"=>"", "format"=>"mp4", "status"=>"Processing", "folder"=>{"id"=>"someIDString"}, "modifiedOn"=>"2015-02-19T15:31:38.94Z", "archiveStatus"=>"Not archived", "restoreStatus"=>"Not restored", "isDeleted"=>false, "isTrashed"=>false, "uploadTransferType"=>"MultipartHttp", "thumbnails"=>[{"type"=>"early", "location"=>"https://foo.cloudfront.net/cifiles/someDirectory/early-thumbnail.jpg?Policy=reallyLongString", "size"=>8723, "width"=>250, "height"=>188}], "proxies"=>[], "acquisitionSource"=>{"name"=>"American Archive"}}
```

Run it through a bash script like this:
```bash
#!/bin/bash

# read tsv (named csv) files to generate SQL to insert ASSET-LEVEL IDENTIFIER data on AMS.AMERICANARCHIVE.ORG
# Copyright 2015, WGBH MLA, by Kevin Carter

# mysql> describe identifiers;
# +-------------------+--------------+------+-----+---------+----------------+
# | Field             | Type         | Null | Key | Default | Extra          |
# +-------------------+--------------+------+-----+---------+----------------+
# | id                | int(11)      | NO   | PRI | NULL    | auto_increment |
# | assets_id         | int(11)      | NO   | PRI | NULL    |                |
# | identifier        | varchar(255) | NO   | MUL | NULL    |                |
# | identifier_source | varchar(255) | NO   |     | NULL    |                |
# | identifier_ref    | varchar(255) | YES  |     | NULL    |                |
# +-------------------+--------------+------+-----+---------+----------------+

usage() {
echo `basename $0`' /path/to/some/specific-formatted-file.tsv | tee /path/to/ams-specific.sql';
echo;
echo 'read the script for assumptions it makes about the format of the tab-separated values and the SQL output';
}

if [ "$#" -ne 1 ];
then usage;
exit 1;
fi;


OLDIFS=$IFS;
IFS=$(echo -en '\n\b');
tab=`printf %s a | tr a '\t'`;


echo "SET @xguids = '';";
echo "SET @indexids = '';";

# NOTE THE USE OF `grep -v '_' to avoid processing currently-missing items affected by Zend/Google library bugwork

# for dataString in `grep '^20' $1  | cut -f2,3 | cut -f3- -d - | grep -v '_' | sed -e "s#\..*$tab#$tab#g" -e "s#_.*$tab#$tab#g"`;
for dataString in `grep '^20' $1  | cut -f2,3 | cut -f3- -d - | grep '_' | sed -e "s#\..*$tab#$tab#g" -e "s#_.*$tab#$tab#g"`;
do 
	
	aaguid='cpb-aacip/'$(echo "$dataString" | cut -f1);
	sonyid=$(echo "$dataString" | cut -f2);
# 	echo 'dataString is   '"$dataString";
# 	echo 'sonyid is   '$sonyid;
	echo "SET @aaguid = '$aaguid';";
	echo "SET @assetid = (select assets_id from identifiers where identifier=@aaguid limit 1);";
	echo "SET @xguids = (SELECT IF(@assetid,@xguids,CONCAT(@xguids,',',@aaguid)));";
	echo "SET @indexids = (SELECT IF(@assetid,CONCAT(@indexids,',',@assetid),@indexids));";
\#	echo "DELETE FROM identifiers WHERE assets_id=@assetid AND identifier_source='Sony Ci';";
	echo "INSERT INTO identifiers (assets_id,identifier,identifier_source) VALUES (@assetid,'$sonyid','Sony Ci');";
	echo;echo '#';echo;

done

nowString=`date +%Y%m%d_%H%M%S`;
echo '# the following requires that the mysql tmp directory exists, has correct permissions and is declared in /etc/my.cnf'
echo "SELECT @xguids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_failures_$nowString.txt';";
echo "SELECT @indexids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_assetids_$nowString.txt';";

IFS=$OLDIFS;
```


To produce SQL like this:
```sql
# here are two variables for OUTFILE report at end of the session
SET @xguids = '';
SET @indexids = '';
# the following structure is repeated for each row of input data
SET @aaguid = 'cpb-aacip/17-00000qrv';
SET @assetid = (select assets_id from identifiers where identifier=@aaguid limit 1);
SET @xguids = (SELECT IF(@assetid,@xguids,CONCAT(@xguids,',',@aaguid)));
SET @indexids = (SELECT IF(@assetid,CONCAT(@indexids,',',@assetid),@indexids));
INSERT INTO identifiers (assets_id,identifier,identifier_source) VALUES (@assetid,'sonydatastring','Sony Ci');
# 
# the following requires that the mysql tmp directory exists, has correct permissions and is declared in /etc/my.cnf
SELECT @xguids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_failures_20150429_170455.txt';
SELECT @indexids INTO OUTFILE '/var/lib/mysql/tmp/sonyci_assetids_20150429_170455.txt';
```

The use of OUTFILE provides data for QA (failures) and for reindexing affected asset (assetids).

The SQL script was generated by the following BASH code:

