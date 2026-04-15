# Stage 1: Build
FROM ruby:3.3-alpine AS build
RUN apk add --no-cache \
    build-base \
    sqlite-dev \
    postgresql-dev \
    tzdata \
    yaml-dev

WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN bundle install
COPY . .

# Stage 2: Production image
FROM ruby:3.3-alpine
RUN apk add --no-cache \
    postgresql-libs \
    sqlite-libs \
    tzdata \
    curl \
    && adduser -D appuser

WORKDIR /app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app .

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]