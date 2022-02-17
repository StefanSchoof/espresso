# syntax=docker/dockerfile:1

# hadolint ignore=DL3029, see https://github.com/hadolint/hadolint/issues/772
FROM --platform=$BUILDPLATFORM node:17-alpine as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --ignore-scripts

COPY . .

RUN npm run build \
    && npm run test:ci \
    && npm run lint

FROM httpd:2.4-alpine
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
COPY --from=builder /usr/src/app/dist/ /usr/local/apache2/htdocs/
