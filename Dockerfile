FROM ruby:2.4.4
WORKDIR /usr/src/app

RUN apt update && apt install -y nodejs curl libcurl3 libcurl3-openssl-dev openjdk-8-jdk && apt-get clean

COPY Gemfile Gemfile.lock ./

RUN bundle install

# COPY . .

EXPOSE 3000

CMD rake jetty:clean && rake jetty:config && rake jetty:start && bundle exec rake db:migrate RAILS_ENV=development && bundle exec rails s -b 0.0.0.0
