FROM ruby:2.5.1
ENV LANG C.UTF-8

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    nodejs \
    vim \
 && rm -rf /var/lib/apt/lists/*

RUN gem install bundler

WORKDIR /tmp
COPY contrast-agent-3.5.0.gem /tmp/contrast-agent-3.5.0.gem
RUN gem install contrast-agent-3.5.0.gem
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD . $APP_HOME

