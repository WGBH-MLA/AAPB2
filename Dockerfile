FROM ruby:2.7
WORKDIR /usr/src/app

RUN apt update && apt install -y nodejs curl libcurl4 libcurl4-openssl-dev default-jdk
RUN gem install bundler -v '~> 1.17.3'
RUN rm /usr/local/lib/ruby/gems/2.7.0/specifications/default/bundler-2.1.4.gemspec
COPY Gemfile ./

RUN bundle install

EXPOSE 3000

CMD rake jetty:clean && rake jetty:config && rake jetty:start && bundle exec rake db:migrate RAILS_ENV=development && bundle exec rails s -b 0.0.0.0
