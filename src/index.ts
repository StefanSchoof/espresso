import { Client, DeviceMethodResponse } from 'azure-iot-device';
import { Mqtt } from 'azure-iot-device-mqtt';
import { exec } from 'child_process';

// tslint:disable-next-line:no-non-null-assertion
const deviceClient: Client = Client.fromConnectionString(process.env['ConnectionString']!, Mqtt);

function showError(err?: Error | undefined): void {
    if (err) {
        console.error(`Error sending response: ${err}`);
    }
}

const log = (...args: Array<any>) => console.log(new Date().toISOString(), ...args);

function execAndResponse(argument: string, description: string, response: DeviceMethodResponse): void {
    log(description);
    exec(`steuerung ${argument}`, err => {
        if (err) {
            const msg = `faild to send ${description}. Error: "${err}"`;
            console.error(msg);
            response.send(500, msg, showError);
        } else {
            response.send(200, `send ${description} to the plug socket`, showError);
        }
    });
}

deviceClient.onDeviceMethod('onSwitchOn', (request, response) => execAndResponse('1', 'power on', response));
deviceClient.onDeviceMethod('onSwitchOff', (request, response) => execAndResponse('0', 'power off', response));

log('Device connect to iot hub');
