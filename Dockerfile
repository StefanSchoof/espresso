FROM resin/rpi-raspbian

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    git \
    wiringpi \
    g++ \
    wget \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

RUN wget https://nodejs.org/dist/v8.11.4/node-v8.11.4-linux-armv6l.tar.xz -O - | \
    tar -xvf - --directory /usr/local --xz --strip 1 --exclude CHANGELOG.md --exclude README.md --exclude LICENSE

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi \
 && mv steuerung /usr/local/bin

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

CMD [ "npm", "start" ]
