FROM resin/rpi-raspbian

RUN apt-get update && apt-get install -y \
    git \
    wiringpi \
    g++ \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --recursive https://github.com/ninjablocks/433Utils.git

COPY steuerung.cpp .

RUN g++ -DRPI 433Utils/rc-switch/RCSwitch.cpp steuerung.cpp -o steuerung -lwiringPi
