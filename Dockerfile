FROM docker/whalesay:latest

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
RUN cd /root/src; tar xvf ruby-2.2.2.tar.gz
RUN cd /root/src/ruby-2.2.2; ./configure; make install

RUN sudo apt-get install -y --force-yes libgeos-dev
RUN sudo apt-get install -y --force-yes libgeos++-dev

RUN gem update --system
RUN gem install bundler

RUN bundle install

EXPOSE 5000
RUN find / -name foreman
CMD ["bundle", "exec", "foreman", "start"]