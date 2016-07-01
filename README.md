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
- Ingest the fixtures: `ruby scripts/download_clean_ingest.rb --same-mount --stdout-log --files spec/fixtures/pbcore/clean-*.xml`
- Start rails: `rails s`

# Code style

We are using [Rubocop's](https://github.com/bbatsov/rubocop) defaults, for the most part.
For simple stuff, like whitespace correction, `rubocop --auto-correct` will make the necessary edits.

# Deployment and Management

### Blog

The blog is hosted by Wordpress. Sadie and Casie are admins.


### DNS

We are using the Wordpress DNS to manage all `*.americanarchive.org` names. This does not give us control over everything:
Wordpress sets a default TTL of 300s, which should be fine for now.


### Media hosting

- Thumbnails are served from the WGBH media server. This has a config `/wgbh/http/streaming/conf/allow-referrer.conf` which prevents unrecognized hosts from leeching from us.
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

- XML: [`/api.xml?q=asimov&fl=id,title,xml&rows=3`](http://americanarchive.org/api.xml?q=asimov&fl=id,title,xml&rows=3)
- JSON: [`/api.json?q=asimov&fl=id,title&rows=3`](http://americanarchive.org/api.json?q=asimov&fl=id,title&rows=3)
- JSONP: [`/api.js?callback=my_callback&q=asimov&fl=id,title&rows=3`](http://americanarchive.org/api.js?callback=my_callback&q=asimov&fl=id,title&rows=3)

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
