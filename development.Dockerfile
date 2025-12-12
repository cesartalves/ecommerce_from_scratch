FROM ruby:3.3

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  postgresql-client \
  build-essential \
  libpq-dev

# Set working directory
WORKDIR /app

# Install gems separately to speed up rebuilds
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Rails dev server command is provided by docker-compose
