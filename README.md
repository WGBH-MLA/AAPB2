[![Build Status](https://travis-ci.org/WGBH/AAPB2.svg?branch=master)](https://travis-ci.org/WGBH/AAPB2)

This is the public-facing website of the [*American Archive of Public Broadcasting*](http://americanarchive.org).

# Getting started

- Install [RVM](https://rvm.io/), if you haven't already: `curl -sSL https://get.rvm.io | bash -s stable`
- Start a new terminal to make the `rvm` command available.
- Clone this repository.
- `cd` to your copy of the repo.
- You may see a message from RVM stating that the required Ruby version is not available. 
Install it as instructed.
- Get dependencies: `bundle install`
- Download Solr, configure, and start: `rake jetty:clean && rake jetty:config && rake jetty:start`
- Run DB migrations: `rake db:migrate RAILS_ENV=development`
(TODO: This shouldn't be necessary, since we don't use the DB.
[Issue #63](https://github.com/WGBH/AAPB2/issues/63))

At this point you can

- Run tests (skipping Ci tests): `rspec --tag ~not_on_travis`
(If it's not 100% passing, let us know!)
- Ingest the fixtures: `ruby scripts/download_clean_ingest.rb --stdout-log --files spec/fixtures/pbcore/clean-*.xml`
- Start rails: `rails s`

# Code style

We are using [Rubocop's](https://github.com/bbatsov/rubocop) defaults, for the most part.
For simple stuff, like whitespace correction, `rubocop --auto-correct` will make the necessary edits.

# Deployment and Management
## Deploy, Server Swap and Ingest Requirements
In order to deploy code to the website, swap servers from demo to live and/or ingest PBCore xml you'll need two additional repositories.

- aapb2_deployment- Found on the internal, WGBH Stash repository
- [aws-wrapper](https://github.com/WGBH/aws-wrapper)

Make sure you first check out these two repositories and pull the latest code.

For WGBH AAPB server resources such as ssh keys, urls, AWS site names, please see [Server Resources](https://wiki.wgbh.org/display/MLA/Server+Resources) documentation on the internal wiki.

If you have all the required applications and dependencies, a good first test would be to see if you can obtain the ip addresses for the current live and demo AAPB servers.

Open your Terminal application.
```
$ cd aws-wrapper
$ ruby scripts/ssh_opt.rb
```

This will give you the list of arguments.  For this initial interaction, you are trying to show the ip address of the demo and live servers.
```
$ ruby scripts/ssh_opt.rb --name aapb.wgbh-mla.org --ips_by_dns
```

The returned result should be the ip address of the live AAPB site.

To do the same for the demo site, change the `—-name` argument to `demo.aapb.wgbh-mla.org`
```
$ ruby scripts/ssh_opt.rb --name demo.aapb.wgbh-mla.org --ips_by_dns
```

The returned result should be the demo server ip address, different from the previous one.

If those commands completed successfully, you can proceed to deploy Github code to the demo server.

## Deploy Code to Demo Server
Because we don't want to immediately deploy new code changes to the live AAPB server, we first deploy them to the demo site where you can verify before swapping the server from live to demo so the live site should always be the most up to date version of the code.


# Deploy code to the demo site
```
$ cd aapb_deployment
```

The next command you'll enter uses the `ssh_opt.rb` script from aws-wrapper to determine and use the demo ip address.  That's why it's important you verify the aws-wrapper is working.
```
$ AAPB_HOST=`cd ../aws-wrapper && ruby scripts/ssh_opt.rb --name demo.aapb.wgbh-mla.org --ips_by_dns` \
AAPB_SSH_KEY=~/.ssh/aapb.wgbh-mla.org.pem bundle exec cap aws deploy
```
Previously when AAPB code was getting deployed, it was wiping out the symlink-ed `jetty` and `log` folders causing search on the site to be broken.  Also, it was omitting the `ci.yml` file causing media files to not playback.
Before you swap demo and live server you may want to:
- Make sure `Jetty` and `log` folders are symlinked from `/shared`
- Make sure the AAPB `ci.yml` file is in the `/config` folder as well
- Restart Jetty if it's not currently running

# Verify Symlink
```
$ cd /var/www/aapb/current
```
See if there is are symlinked `jetty` and `log` directories there.
If not, do these steps.
```
$ ln -s /var/www/aapb/shared/jetty/ /var/www/aapb/current/
$ ln -s /var/www/aapb/shared/log/ /var/www/aapb/current/
```

# Restarting Jetty If It's Not Running
If on the demo site you can't do a search, it probably means Jetty isn't running.
Also in the `/current` directory, first make sure the Jetty process is actually stopped.
`$ RAILS_ENV=production bundle exec rake jetty:stop`
Then start it again, this time it should start the symlink-ed one.
`$ RAILS_ENV=production bundle exec rake jetty:start`

# Check for ci.yml file
There should be a file called `ci.yml` in the `/current/config` directory.
```
$ cd /var/www/aapb/current/config
$ ls
```
If you don't see it there you need to get a version of the file from the live site, or from Kevin or Mike.
Copy it to `/var/www/aapb/current/config` by doing:

```
scp -i ~/.ssh/aapb.wgbh-mla.org.pem ~/ci.yml ec2-user@DEMO-IP-ADDRESS:/var/www/aapb/current/config/ci.yml
```

NOTE- If you had to do any of those steps, there may be a problem with the aapb_deployment code and you should file a new ticket.  

When complete, [go to the demo site](http://demo.aapb.wgbh-mla.org) and verify the code changes that were just deployed are what you desire and the search is working correctly, and media playback is working.

If so, now you'll want to swap the servers so the demo site becomes the public, live site.

## Swap Servers
This will switch which server is the demo and which one is the live.
```
$ cd aws-wrapper
$ ruby scripts/swap.rb --name aapb.wgbh-mla.org
```

When that process completes, you can go to the [live AAPB](http://americanarchive.org) and verify that the new code came deploy that had previously been on the demo site is now live.  You can also visit the demo url if you wish to see if the non-updated code is still in place.

## Ingest to AAPB
	TO DO CURRENTLY HANDLED IN `guids2AAPB.app`
	
	
## Verify Successful Ingest
To verify ingest completed successfully you can view the most recent ingest log files on both the demo and live servers.
View the most recent log file.  At the end of the log there should be a % complete number.  If it's `(100%) succeeded` then the ingest was successful.

Verify log file on live site:
```
$ cd aws-wrapper
$ ssh -i ~/.ssh/aapb.wgbh-mla.org.pem ec2-user@`ruby scripts/ssh_opt.rb --name aapb.wgbh-mla.org --ips_by_dns`
$ cd /var/www/aapb/current/log
$ ls -l
$ less ingest.2016-03-28_190938.log
```

Verify log file on demo site:
```
$ cd aws-wrapper
$ ssh -i ~/.ssh/aapb.wgbh-mla.org.pem ec2-user@`ruby scripts/ssh_opt.rb --name demo.aapb.wgbh-mla.org --ips_by_dns`
$ cd /var/www/aapb/current/log
$ ls -l
$ less ingest.2016-03-28_190938.log
```

If the ingest was not 100% on either server then you need to review the log file and determine why the failing records are failing, correct the data, then re-import those records.

There may be instances where the ingest is successful on the live site but not the demo.  This could be because code changes that are currently deployed to the live site that would allow xml to be valid have not yet been deployed to the now demo site.  In those cases, follow the Deploy Code to Demo Server instructions and re-ingest the same xml.

Once you've verified the ingest was 100% successful, you should spot check the records themselves on the live and sites.


### Stopping and Starting Demo
There may be cases where you need to stop and start the demo EC2 instance. We don't recommend this because AAPB gets it's index updated so frequently it may be confusing to manage.
But, should you need to start or stop, follow these instructions.

To stop
```
$ cd aws-wrapper
$ ruby scripts/stop.rb --name demo.aapb.wgbh-mla.org
```
To start
```
$ cd aws-wrapper
$ ruby scripts/start.rb --name demo.aapb.wgbh-mla.org
```

After starting and deploying you may need to:
- Make sure `Jetty` and `log` folders are symlinked from `/shared`
- Make sure the AAPB `ci.yml` file is in the `/config` folder as well
- Restart Jetty

### Blog

The blog is hosted by Wordpress. Sadie and Casie are admins.


### DNS

We are using the Wordpress DNS to manage all `*.americanarchive.org` names. This does not give us control over everything:
Wordpress sets a default TTL of 300s, which should be fine for now.


### Media hosting

- Thumbnails are served from a Amazon S3 server. 
To ingest thumbnails:
You can use the AWS web interface to upload small batches of thumbnails but for uploading hundreds of files you should use the Amazon CLI tool.  The transfer speed is a lot faster and large transfers shouldn't time out.

[Follow the documentation](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) to set up CLI with your Access Key, Secret Access Key, and Default region name.

- /thumbnail/ is for image thumbnails for all the digitized video assets

Copy Directory of Files to S3:
```
aws s3 cp /local/folder/of/thumbnails s3://americanarchive.org/thumbnail -- recursive
```

Double Check Files Were Uploaded:
```
aws s3 ls s3://americanarchive.org/thumbnail --recursive >> /Users/logs/s3_proxies.csv
```

- Videos are served from Sony Ci. We need to hit their API to generate temporary download URLs, which we then redirect to.


### Deploying to production

There are four steps to get the site up from scratch:
- Request servers and everything else from AWS.
- Use Ansible for a basic configuration of the servers.
- Deploy the site with Capistrano.
- Ingest the PBCore.

On an on-going basis there will be:
- Capistrano redeploys to the demo server
- and swaps of the production and demo servers.

### AMS Ingest

Each bulk ingest to the AMS has been a little different, so we don't have a single script, but there are [notes](https://github.com/WGBH/AAPB2/blob/master/docs/ams-ingest.md) which might help.

### Indexing

Get `aapb.pem` from Chuck or Drew and log in to the remote machine:
```bash
$ ssh -i ~/.ssh/aapb.pem ec2-user@americanarchive.org
$ cd /srv/www/aapb/current/
```

To download and ingest everything on the server (which will take a while):
```bash
$ nohup bundle exec ruby scripts/download_clean_ingest.rb --all &
```

(The script can be run in several modes. Run it without arguments for more details:
`bundle exec ruby scripts/download_clean_ingest.rb`.)


### Sony Ci

We are using [Sony Ci](http://developers.cimediacloud.com) to host the video and audio files.
In the office we are using the Ci API to upload content, and on the server the API
is used to generate transient download URLs. On either end, an additional 
git-ignored configuration file (`config/ci.yml`) is necessary.

```yaml
username: [your ci username]
password: [your ci password]
client_id: [32 character hexadecimal client ID]
client_secret: [32 character hexadecimal client secret]
workspace_id: [32 character hexadecimal workspace ID]
```

Use your personal workspace ID if you are working on the Ci code itself, or the 
AAPB workspace ID if you want to view media that is stored.

To actually ingest:

```bash
$ echo /PATH/TO/FILES/* | xargs -n 10 ruby scripts/ci/ci.rb --log ~/ci_log.tab --up &
$ # A big directory may have more files than ruby can accommodate as arguments, so xargs
$ tail -f ~/ci_log.tab
```

**TODO**: How does the data get to the AMS?

# Configuration

There are a number of things non-developers can tweak and submit PRs for:

**Controlled Vocabularies**: The original data does not conform to any controlled vocabulary on most fields.
Doing a massive find-and-replace is scary, so instead we clean up the data during
ingest. Vocabularies which we remap are specified at `config/vocab-maps`: These files
specify both the replacements to be made, and the preferred display order in the UI.

**Organizations**: The organization pages are controlled by `config/organizations.yml`.
The descriptions and histories respect paragraph breaks and have a notation for links.
If we need more, we should investigate markdown.

**Views**: All the ERBs under `app/views` as well as the CSS under `app/assets/stylesheets`
are tweakable. We have good test coverage, so if something is simply invalid, 
it should cause Travis to fail.

**Solr**: It is unlikely that non-devs would touch Solr, but it bears mentioning here.
There are two big differences from a standard Blacklight deployment:
- We are not using Blacklight dynamic fields in `schema.xml`: In my experience,
configuration-by-naming-convention has tended to obscure the actual meaning of the
definitions, and when a change does need to be made, it requires tracking down
occurrences throughout the codebase.
- We minimize the dependence of the view code on the Solr definitions by always
pulling data to render from a `PBCore` object, rather than a Solr field.
This does mean the search results page is a little slower, (about 0.1s when I timed it,)
but it means that access is consistent in all contexts, and if we do want to make a change 
in how data is pulled from PBCore for display, it does not require a re-index.


# Data Flow

![data flow diagram](https://cdn.rawgit.com/WGBH/AAPB2/master/docs/aapb-data-flow.svg?v2)

# API

Data from the AAPB is available via an API. At this moment the API is experimental:
No key is required, but we also do not guarantee continued availability. 

The OAI-PMH feed can be used to harvest records for items available in the Online Reading Room. Please note that **only records for items in the Online Reading Room** can be harvested this way. We don't support
all the verbs, or any formats beyond MODS.

- OAI-PMH: [`/oai.xml?verb=ListRecords`](http://americanarchive.org/oai.xml?verb=ListRecords)

All AAPB metadata records, including records for all digitized content and content not digitized can be harvested using the PBCore API. 

If you just need one or a small number of records in machine-readable form, 
use the single-item API to get [PBCore XML](http://pbcore.org/):

- XML: [`/api/cpb-aacip_305-7312jttj.xml`](http://americanarchive.org/api/cpb-aacip_305-7312jttj.xml)

If you are interested in summary statistics across the collection,
an advanced API provides limited access to the underlying Solr index. XML, JSON, and JSONP
are available. All have CORS turned on for consumption by 3rd party sites.

- XML: [`/api.xml?q=asimov&fl=id,title,xml&rows=3&start=5`](http://americanarchive.org/api.xml?q=asimov&fl=id,title,xml&rows=3&start=5)
- JSON: [`/api.json?q=asimov&fl=id,title&rows=3&start=5`](http://americanarchive.org/api.json?q=asimov&fl=id,title&rows=3&start=5)
- JSONP: [`/api.js?callback=my_callback&q=asimov&fl=id,title&rows=3&start=5`](http://americanarchive.org/api.js?callback=my_callback&q=asimov&fl=id,title&rows=3&start=5)

The `rows` parameter can be set as high as 100, and a result set can be paged through with `start`.

Note that while the PBCore XML is available through this API, it is simply represented
as a string within the container: Even with the XML response type a first parse would
be necessary to extract the PBCore, which could then in its turn be parsed.

Solr query syntax is beyond the scope of this document, but 
[extensive documentation](http://wiki.apache.org/solr/CommonQueryParameters) is available.
**NOTE**: Repeated parameters must be followed by `[]` when using the API. This is different
from native Solr syntax. For example:
[`facet.field[]=state&facet.field[]=year`](http://americanarchive.org/api.json?facet=true&q=asimov&facet.field[]=state&facet.field[]=year)

The available facets correspond closely to what is available through the UI,
but check the [schema](https://raw.githubusercontent.com/WGBH/AAPB2/master/solr_conf/schema.xml) 
in this repo if you are curious.

We've made a few simple D3 [visualizations](http://mccalluc.github.io/alt-aapb/) 
of the AAPB collection that suggest some of the possibilities. If you build anything interesting, 
we'd love to hear about it, and if we have your email, we'll try to notify you about changes to the API.
