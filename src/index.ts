import { Client, DeviceMethodResponse } from 'azure-iot-device';
import { Mqtt } from 'azure-iot-device-mqtt';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as appInsights from 'applicationinsights';

const log = (...args: Array<any>) => {
    appInsights.defaultClient.trackTrace({message: args[0]});
    console.log(new Date().toISOString(), ...args);
};

const execAsync = promisify(exec);

async function execAndResponse(argument: string, description: string, response: DeviceMethodResponse): Promise<void> {
    const startTime = Date.now();
    log(description);
    let msg: string;
    let resultCode: number;
    try {
        await execAsync(`steuerung ${argument}`);
        msg = `send ${description} to the plug socket`;
        resultCode = 200;
    } catch (e) {
        appInsights.defaultClient.trackException({exception: e});
        msg = `failed to send ${description}. Error: "${e}"`;
        resultCode = 500;
        console.error(msg);
    }
    try {
        await promisify((cb: (err?: Error) => void) => response.send(resultCode, msg, cb))();
        const duration = Date.now() - startTime;
        appInsights.defaultClient.trackRequest(
            {url: `mqtts://espresso/${argument}`,
            name: `steuerung ${argument}`,
            duration,
            resultCode,
            success: resultCode === 200});
    } catch (e) {
        appInsights.defaultClient.trackException({exception: e});
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
