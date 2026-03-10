# Stage 1: Build
FROM ruby:3.3-alpine AS build
RUN apk add --no-cache build-base sqlite-dev tzdata
WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN bundle install
COPY . .

# Stage 2: Production image
FROM ruby:3.3-alpine
RUN apk add --no-cache sqlite-dev tzdata curl \
    && adduser -D appuser

WORKDIR /app

# Copy only what we need from the build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app .

# Switch to non-root user
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
ENV RACK_ENV=production

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]