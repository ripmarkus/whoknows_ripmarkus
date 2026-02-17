FROM ruby:3.3-alpine

RUN apk add --no-cache build-base sqlite-dev tzdata
WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

EXPOSE 8080

ENV RACK_ENV=production
CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]