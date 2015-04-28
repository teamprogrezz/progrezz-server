# Ruby 2.2.0
FROM ruby:2.2.0

# throw errors if Gemfile has been modified since Gemfile.lock
# RUN bundle config --global frozen 1

# Setup workspace
RUN mkdir -p /usr/progrezz
WORKDIR /usr/progrezz

# Setup gems
COPY Gemfile /usr/progrezz/
COPY Gemfile.lock /usr/progrezz/
RUN bundle install

# Copy app
COPY . /usr/progrezz/

# Set extra enviroment vars
# ...

# By default, exec "rake run".
CMD rake development

# To run this app, just build it with
