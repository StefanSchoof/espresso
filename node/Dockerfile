ARG NODE_VERSION=12
FROM alpine as cppbuilder

WORKDIR /usr/src/app
RUN apk add --no-cache wiringpi-dev g++ git

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi

FROM node:${NODE_VERSION}-alpine as builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --ignore-scripts

COPY . .

RUN npm run build \
 && npm run test:ci \
 && npm run lint \
 && npm prune --production \
 && mv node_modules dist/

FROM scratch as testresult

COPY --from=builder /usr/src/app/junit.xml .
COPY --from=builder /usr/src/app/coverage coverage

FROM node:${NODE_VERSION}-alpine as runner

WORKDIR /usr/app

COPY --from=cppbuilder /usr/lib/libwiringPi.so.* /usr/lib/
COPY --from=cppbuilder /usr/src/app/steuerung /usr/local/bin/
COPY --from=builder /usr/src/app/dist/ .

CMD [ "node", "main.js" ]
