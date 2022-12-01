FROM ruby:2.4
WORKDIR /usr/src/app

RUN apt update && apt install -y nodejs curl libcurl4 libcurl4-openssl-dev default-jdk

COPY Gemfile Gemfile.lock ./

RUN bundle install

EXPOSE 3000

CMD rake jetty:clean && rake jetty:config && rake jetty:start && bundle exec rake db:migrate RAILS_ENV=development && bundle exec rails s -b 0.0.0.0
