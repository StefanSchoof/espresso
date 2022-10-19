# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM node:19-alpine as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN --mount=type=cache,target=/usr/src/.npm \
    npm set cache /usr/src/.npm && \
    npm install --ignore-scripts

COPY . .

RUN npm run build \
    && npm run test:ci

FROM httpd:2.4-alpine
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
COPY --link --from=builder /usr/src/app/dist/ /usr/local/apache2/htdocs/
