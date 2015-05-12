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
- Start Solr: `rake jetty:start`
- Run DB migrations: `rake db:migrate RAILS_ENV=development`
(TODO: This shouldn't be necessary, since we don't use the DB.
[Issue #63](https://github.com/WGBH/AAPB2/issues/63))

At this point you can

- Run tests (skipping Ci tests): `rspec --tag ~not_on_travis`
(If it's not 100% passing, let us know!)
- Ingest the fixtures: `ruby scripts/download_clean_ingest.rb --same-mount --files spec/fixtures/pbcore/clean-*.xml`
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


### AWS OpsWorks

*TODO*: This has been in flux.

<!-- https://cdn.rawgit.com/WGBH/AAPB2/master/docs/aapb-servers.svg?v1 -->

### Indexing

Want to blow away the index before you start?
```bash
  # DELETES EVERYTHING!
$ ruby -I . -e 'require "scripts/lib/pb_core_ingester"; PBCoreIngester.new(same_mount: true).delete_all'
```
To download and ingest everything on the server (which will take a while):
```bash
$ nohup ruby scripts/download_clean_ingest.rb --all &
```

(The script can be run in several modes. Run it without arguments for more details:
`ruby scripts/download_clean_ingest.rb`.)


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
