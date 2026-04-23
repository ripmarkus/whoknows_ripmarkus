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


# Download Tailwind CLI v4 (musl build for Alpine) and compile CSS
RUN apk add --no-cache curl
RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/download/v4.2.4/tailwindcss-linux-x64-musl && \
    echo "d2c074a053f3cb63e3c250e16accabbac9c8aa704bb7d1bd53781ee5dde0e65e  tailwindcss-linux-x64-musl" | sha256sum -c - && \
    chmod +x tailwindcss-linux-x64-musl && \
    ./tailwindcss-linux-x64-musl -i ./public/input.css -o ./public/output.css --minify

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