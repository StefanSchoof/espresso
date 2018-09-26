import { Client, DeviceMethodResponse } from 'azure-iot-device';
import { Mqtt } from 'azure-iot-device-mqtt';
import { exec } from 'child_process';
import { promisify } from 'util';

const log = (...args: Array<any>) => console.log(new Date().toISOString(), ...args);
const execAsync = promisify(exec);

async function execAndResponse(argument: string, description: string, response: DeviceMethodResponse): Promise<void> {
    log(description);
    let msg: string;
    let code: number;
    try {
        await execAsync(`steuerung ${argument}`);
        msg = `send ${description} to the plug socket`;
        code = 200;
    } catch (e) {
        msg = `failed to send ${description}. Error: "${e}"`;
        code = 500;
        console.error(msg);
    }
    try {
        await promisify((cb: (err?: Error) => void) => response.send(code, msg, cb))();
    } catch (e) {
        console.error(`Error sending response: ${e}`);
        throw e;
    }
}

export function init(connectionString?: string): void {
    if (connectionString === undefined) {
        throw new Error('connectionString needs a value');
    }
    const deviceClient: Client = Client.fromConnectionString(connectionString, Mqtt);
    deviceClient.onDeviceMethod('onSwitchOn', (request, response) => execAndResponse('1', 'power on', response));
    deviceClient.onDeviceMethod('onSwitchOff', (request, response) => execAndResponse('0', 'power off', response));

    log('Device connect to iot hub');
}
