FROM ruby:2.4.4 as base
WORKDIR /usr/src/app

RUN /bin/echo -e "deb http://archive.debian.org/debian stretch main\ndeb http://archive.debian.org/debian-security stretch/updates main\n" > /etc/apt/sources.list
# Add the Debian archive keyring to resolve key expiration issues
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50 04EE7237B7D453EC EF0F382A1A7B6500

# Update the sources.list to use the archived repositories
RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' /etc/apt/sources.list

# Allow the use of unsigned repositories (necessary for EOL distributions)
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99-nocheck-valid-until && \
    echo 'Acquire::AllowInsecureRepositories "true";' >> /etc/apt/apt.conf.d/99-nocheck-valid-until

# Install non-ruby dependencies
RUN apt update && apt install -y nodejs curl libcurl3 libcurl3-openssl-dev openjdk-8-jdk

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
