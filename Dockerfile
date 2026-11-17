# syntax=docker/dockerfile:1
# Stage 1: build the static site. Runs once on the build machine's own
# architecture; its output (plain HTML/CSS/JS) is architecture-independent.
FROM --platform=$BUILDPLATFORM node:22-bookworm-slim AS build

ARG HUGO_VERSION=0.150.1
ARG PAGEFIND_VERSION=1.5.2
ARG BASE_URL=https://zamrabbaney.site/
ARG BUILDARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

# Go is required for Hugo Modules (the Hugo Blox theme is a Go module).
COPY --from=golang:1.23-bookworm /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH

RUN curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${BUILDARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin hugo \
 && hugo version

RUN corepack enable
WORKDIR /src

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN hugo --gc --minify -b "${BASE_URL}" \
 && pnpm dlx "pagefind@${PAGEFIND_VERSION}" --site public

# Stage 2: tiny runtime image that only serves files.
FROM caddy:2.10.2-alpine
COPY deploy/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /src/public /srv
