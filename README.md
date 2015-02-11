[![Build Status](https://travis-ci.org/WGBH/AAPB2.svg?branch=master)](https://travis-ci.org/WGBH/AAPB2)

The public-facing website of the the *American Archive of Public Broadcasting*.

For more information:
- [About the project](http://americanarchive.org/about-the-american-archive/)
- [Interim access portal](http://americanarchiveinventory.org/)

The code is not yet deployed: Its home will be [americanarchive.org](http://americanarchive.org).
(That is currently the blog.)

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

If you'll be interacting with [Sony Ci](http://developers.cimediacloud.com), you'll also need `config/ci.yml`.
(This is git-ignored since it contains a data which should not be publicized.)

```yaml
username: [your ci username]
password: [your ci password]
client_id: [32 character hexadecimal client ID]
client_secret: [32 character hexadecimal client secret]
workspace_id: [32 character hexadecimal workspace ID]
```

Use your personal workspace ID if you are working on the Ci code itself, or the 
AAPB workspace ID if you want to view media that is stored.

At this point you can

- Run tests, skipping Ci tests: `rspec --tag ~not_on_travis`
(If it's not 100% passing, let us know!)
- Ingest the fixtures: `ruby scripts/pb_core_ingester.rb spec/fixtures/pbcore/clean-*.xml`
- or... ingest recent updates from AMS: 
```bash
ruby scripts/download_clean_ingest.rb 3 # Records updated in the last 3 days
ruby scripts/download_clean_ingest.rb   # All records from AMS
```
- Start rails: `rails s`

# Architecture

![data flow diagram](https://cdn.rawgit.com/WGBH/AAPB2/master/docs/aapb-data-flow.svg?v1)