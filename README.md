[![Build Status](https://travis-ci.org/WGBH/AAPB2.svg?branch=master)](https://travis-ci.org/WGBH/AAPB2)

The public-facing website of the the *American Archive of Public Broadcasting*.

For more information:
- [About the project](http://americanarchive.org/about-the-american-archive/)
- [Interim access portal](http://americanarchiveinventory.org/)

The code is deployed at [beta.americanarchive.org](http://beta.americanarchive.org); Its long-term home will be [americanarchive.org](http://americanarchive.org).
(That currently redirects to the blog.)


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
- Ingest the fixtures: `ruby scripts/download_clean_ingest.rb --files spec/fixtures/pbcore/clean-*.xml`
- Start rails: `rails s`


# Deployment and Management

### Blog

The blog is hosted by Wordpress. Sadie and Casie are admins.


### AWS OpsWorks

**TODO**

#### Deployment
- Get an AWS account.
- Talk to one of us and get access to the AAPB OpsWorks stack: If you go to 
https://console.aws.amazon.com/opsworks/home you should have an option for AAPB.
- From the AAPB stack page, click on instances: You can redeploy from here.

#### Management
The goal is to have ingests of the latest data should be automatic. 
But for now we need to log in...

```bash
$ ssh-keygen -t rsa -f opsworks
$ mv opsworks* ~/.ssh
$ chmod 400 ~/.ssh/opsworks
$ cat ~/.ssh/opsworks.pub
```
Copy this public key, and then in OpsWorks, click on "My Settings" in the upper right,
"Edit", paste in the "Public SSH Key", "Save", and then:
```bash
$ ssh -i ~/.ssh/opsworks USERNAME@54.167.213.134 # TODO: DNS
$ cd /srv/www/aapb/current
$ sudo chown deploy:apache /mnt/* # needed for the next section
$ sudo su deploy
$ bundle install
$ rake jetty:start
```
The disk space that comes with an EC2 instance is ephemeral: not that we expect instances to go down, but still.
So for downloading and indexing we have EBS volumes symlinked to the appropriate locations:
```bash
$ rm -rf tmp/pbcore/download
$ ln -s /mnt/aapb-downloads tmp/pbcore/download
$ rm -rf jetty/solr/blacklight-core/data/index
$ ln -s /mnt/aapb-index jetty/solr/blacklight-core/data/index
```
At this point for the ingest script to work, we need a symlink to the gems. 
There is probably a better way to do this:
```bash
$ mkdir -p ~/.gem/ruby # Might not exist?
$ ln -s ~/.bundler/aapb/ruby/2.1.0 ~/.gem/ruby/2.1.0
  # This should list everything bundle installed:
$ ruby -e 'Gem.path.each{|dir|puts Dir["#{dir}/gems/*"]}'
```
Want to blow away the index before you start?
```bash
  # DELETES EVERYTHING!
$ ruby -I . -e 'require "scripts/lib/pb_core_ingester"; PBCoreIngester.new.delete_all'
```
To download and ingest everthing (which will take a while):
```bash
$ nohup ruby scripts/download_clean_ingest.rb --all >> tmp/ingest.log 2>> tmp/ingest.err &
$ cat tmp/ingest.err # to make sure it started without errors
```


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

**Organizations**: The organization pages are controlled by `config/organizations.xml`, and MS Excel XML
file. We chose this format because it is easy to edit, accommodates Unicode, and
preserves newlines.

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
