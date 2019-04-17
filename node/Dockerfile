#x86only FROM debian:testing as qemu

#x86only RUN apt-get update && apt-get install -y \
#x86only     qemu-user-static \
#x86only  && rm -rf /var/lib/apt/lists/*

#x86only CMD update-binfmts --enable qemu-arm

FROM --platform=linux/arm/v6 alpine as cppbuilder

#x86only COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin

WORKDIR /usr/src/app
RUN apk add --no-cache wiringpi-dev g++ git

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi

FROM --platform=linux/arm/v6 node:10-alpine as builder

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

FROM --platform=linux/arm/v6 node:10-alpine as runner

WORKDIR /usr/app

#x86only COPY --from=qemu /usr/bin/qemu-arm-static /usr/bin
COPY --from=cppbuilder /usr/lib/libwiringPi.so.* /usr/lib/
COPY --from=cppbuilder /usr/src/app/steuerung /usr/local/bin/
COPY --from=builder /usr/src/app/dist/ .

CMD [ "node", "main.js" ]
