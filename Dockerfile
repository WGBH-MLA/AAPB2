FROM ruby:2.4.4 as base
WORKDIR /usr/src/app

RUN /bin/echo -e "deb http://archive.debian.org/debian stretch main\ndeb http://archive.debian.org/debian-security stretch/updates main\n" > /etc/apt/sources.list

RUN apt update && apt install -y nodejs curl libcurl3 libcurl3-openssl-dev openjdk-8-jdk

COPY Gemfile Gemfile.lock ./

RUN bundle install

EXPOSE 3000

CMD rake jetty:clean && rake jetty:config && rake jetty:start && bundle exec rake db:migrate RAILS_ENV=development && bundle exec rails s -b 0.0.0.0

FROM base as production

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*


COPY . .

RUN rake jetty:clean && rake jetty:config && rake assets:precompile

CMD rake jetty:start && bundle exec rake db:migrate RAILS_ENV=production && bundle exec rails s -b 0.0.0.0
