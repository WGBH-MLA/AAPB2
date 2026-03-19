FROM ruby:2.4.4 as base
WORKDIR /usr/src/app

RUN /bin/echo -e "deb http://archive.debian.org/debian stretch main\ndeb http://archive.debian.org/debian-security stretch/updates main\n" > /etc/apt/sources.list

# Install non-ruby dependencies
RUN apt update && apt install -y --allow-unauthenticated nodejs curl libcurl3 libcurl3-openssl-dev openjdk-8-jdk

# Copy source code to container
COPY . .


############################
# Development Build Stage
############################
FROM base as development

# Set the RAILS_ENV to production. This affects several things in Rails.
ENV RAILS_ENV=development

# Update the bundle from Gemfile to pull in any newer versions not committed to
# Gemfile.lock yet.
RUN bundle update

# Install fresh jetty instance
RUN bundle exec rake jetty:clean

EXPOSE 3000

# Run several commmands to start the development server:
# 1. bundle exec rake jetty:config
#      Copies jetty configuration from config/jetty.yml to jetty instance,
#      which is installed in the 'base' build stage.
# 2. bundle exec rake jetty:start
#      Starts jetty server
# 3. bundle exec rake db:migrate
#      Runs databae migrations, if any need to be run.
# 4. bundle exec rails s -b 0.0.0.0
#      Starts the Rails server.
CMD bundle exec rake jetty:config \
    bundle exec rake jetty:start && \
    bundle exec rake db:migrate && \
    bundle exec rails s -b 0.0.0.0


############################
# Production Build Stage
############################
FROM base as production

# Set the RAILS_ENV to production. This affects several things in Rails.
ENV RAILS_ENV=production

# TODO: is this needed?
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Update the bundle from Gemfile.lock (don't update the Bundle in production)
RUN bundle install

# Run commands atomically to start production AAPB web application:
# 1. bundle exec rake jetty:start
#      Starts the jetty server
# 2. bundle exec rails s -b 0.0.0.0
#      Starts the Rails server.
CMD bundle exec rake jetty:start && \
    bundle exec rails s -b 0.0.0.0
    