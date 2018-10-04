#include "433Utils/rc-switch/RCSwitch.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    int PIN = 0; // siehe wiring Pi Belegung
    int codeSocketDon = 327701;
    int codeSocketDoff = 327700;

    if (wiringPiSetup() == -1) return 1;

    RCSwitch mySwitch = RCSwitch();
    mySwitch.enableTransmit(PIN);

    if (atoi(argv[1]) == 1) { // hier kannst du deine eigenen Bedingungen setzen
        mySwitch.send(codeSocketDon, 24);
    } else {
        mySwitch.send(codeSocketDoff, 24);
    }
    return 0;
}
