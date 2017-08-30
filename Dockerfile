FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y libpq-dev libmysqlclient-dev
WORKDIR /app
ADD . /app
