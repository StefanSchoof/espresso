# want qemu 3.1, other logs some error. currently only in sid
# see https://tracker.debian.org/pkg/qemu
#x86only FROM debian:unstable as qemu

#x86only RUN apt-get update && apt-get install -y \
#x86only     qemu-user-static \
#x86only  && rm -rf /var/lib/apt/lists/*

FROM alpine as cppbuilder

#x86only COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin

WORKDIR /usr/src/app
RUN apk add --no-cache --repository http://dl-4.alpinelinux.org/alpine/edge/community wiringpi-dev \
 && apk add --no-cache g++ git

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi

FROM node:10-alpine as builder

#x86only COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build \
 && npm run test:ci \
 && npm run lint \
 && npm prune --production \
 && mv node_modules dist/

FROM node:10-alpine as runner

WORKDIR /usr/app

#x86only COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin
COPY --from=cppbuilder /usr/lib/libwiringPi.so.* /usr/lib/
COPY --from=cppbuilder /usr/src/app/steuerung /usr/local/bin/
COPY --from=builder /usr/src/app/dist/ .

CMD [ "node", "main.js" ]
