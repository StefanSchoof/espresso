FROM alpine as cppbuilder

WORKDIR /usr/src/app
RUN apk add --no-cache --repository http://dl-4.alpinelinux.org/alpine/edge/community wiringpi-dev \
 && apk add --no-cache g++ git

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi

FROM node:10-alpine as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build \
 && npm run test \
 && npm run lint

FROM node:10-alpine as runner

RUN apk add --no-cache --repository http://dl-4.alpinelinux.org/alpine/edge/community wiringpi

WORKDIR /usr/src/app

COPY --from=cppbuilder /usr/src/app/steuerung /usr/local/bin/

COPY package*.json ./

RUN npm install --production
COPY --from=builder /usr/src/app/dist/*.js /usr/src/app/dist/

CMD [ "npm", "start" ]
