FROM ruby:2.1.2

RUN apt-get update && apt-get install -y wget
RUN wget https://github.com/jwilder/dockerize/releases/download/v0.1.0/dockerize-linux-amd64-v0.1.0.tar.gz
RUN tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.1.0.tar.gz

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY ./Gemfile /usr/src/app/Gemfile
COPY ./Gemfile.lock /usr/src/app/Gemfile.lock

RUN gem update --system && \
    bundle install

COPY . /usr/src/app

EXPOSE 5000
# RUN find / -name foreman
RUN touch /var/log/cron.log

ENTRYPOINT ["dockerize", "-wait", "tcp://db:5432"]
