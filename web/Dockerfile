# syntax=docker/dockerfile:1

FROM node:17-alpine as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --ignore-scripts

COPY . .

RUN npm run build \
    && npm run test:ci \
    && npm run lint

FROM --platform=linux/arm/v7 httpd:2.4-alpine
COPY --from=builder /usr/src/app/dist/ /usr/local/apache2/htdocs/