FROM docker/whalesay:latest

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
RUN cd /root/src; tar xvf ruby-2.1.2.tar.gz
RUN cd /root/src/ruby-2.1.2; ./configure; make install

RUN sudo apt-get install -y --force-yes libgeos-dev
RUN sudo apt-get install -y --force-yes libgeos++-dev
RUN sudo apt-get install -y --force-yes libpq-dev

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

RUN gem update --system
RUN gem install bundler

RUN bundle install
COPY . /usr/src/app

EXPOSE 5000
RUN find / -name foreman
RUN touch /var/log/cron.log
CMD cron && tail -f /var/log/cron.log