# Stage 1: Build
FROM ruby:3.3-alpine AS build
RUN apk add --no-cache build-base sqlite-dev tzdata yaml-dev
WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN bundle install
COPY . .


# Download Tailwind CLI and compile CSS
RUN apk add curl
RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.17/tailwindcss-linux-x64 && \
    echo "7d24f7fa191d2193b78cd5f5a42a6093e14409521908529f42d80b11fde1f1d4  tailwindcss-linux-x64" | sha256sum -c - && \
    chmod +x tailwindcss-linux-x64 && \
    ./tailwindcss-linux-x64 -i ./public/input.css -o ./public/output.css --minify

# Stage 2: Production image
FROM ruby:3.3-alpine
RUN apk add --no-cache sqlite-dev tzdata \
    && adduser -D appuser

WORKDIR /app

# Copy only what we need from the build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app .

# Switch to non-root user
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 4567

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "8080"]