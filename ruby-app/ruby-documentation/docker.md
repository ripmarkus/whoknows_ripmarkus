# Docker

Our Dockerfile takes a lot of inspiration from this [article](https://dev.to/code42cate/stop-using-docker-like-its-2015-1o5l).

*The key points:*

- Multistage build, meaning that we separate the build environment and the runtime environment, so that the compilers
and build tools don't ship to production.
- Non root user, this reduces the blast radius of any container escape, enhancing the security.
- `.dockerignore`, keeps non-app files and test files out of the build context

*First draft, before:*
```docker
FROM ruby:3.3-alpine

RUN apk add --no-cache build-base sqlite-dev tzdata
WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

EXPOSE 8080

ENV RACK_ENV=production
CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]
```

*Final(ish) draft, after:*
```docker
# stage 1: Build
FROM ruby:3.3-alpine AS build
RUN apk add --no-cache build-base sqlite-dev tzdata
WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN bundle install
COPY . .

# stage 2: Production image
FROM ruby:3.3-alpine
RUN apk add --no-cache sqlite-dev tzdata curl \
    && adduser -D appuser

WORKDIR /app

# copy only what we need from the build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app .

# switch to non-root user
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
ENV RACK_ENV=production

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]
```