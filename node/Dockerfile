FROM resin/rpi-raspbian as node

ENV NODE_VERSION 10.13.0

RUN curl -sSL --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-armv6l.tar.xz" | \
    tar -xf - --directory /usr/local --xz --strip 1 --exclude CHANGELOG.md --exclude README.md --exclude LICENSE

FROM resin/rpi-raspbian as cppbuilder

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    git \
    wiringpi \
    g++ \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi

FROM node as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build \
 && npm run test:ci \
 && npm run lint

FROM node as runner

RUN apt-get update && apt-get install -y \
    wiringpi \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY --from=cppbuilder /usr/src/app/steuerung /usr/local/bin/

COPY package*.json ./

RUN npm install --production
COPY --from=builder /usr/src/app/dist/*.js /usr/src/app/dist/

CMD [ "npm", "start" ]
