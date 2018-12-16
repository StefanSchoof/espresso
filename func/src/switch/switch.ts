import { HttpContext, IFunctionRequest } from 'azure-functions-typescript';
import * as msRestAzure from 'ms-rest-azure';
import { KeyVaultClient } from 'azure-keyvault';
import { Client, DeviceMethodParams } from 'azure-iothub';
import { promisify } from 'util';

const deviceId = 'espressoPi';

async function getConnectionString(): Promise<string> {
    const cred = process.env.APPSETTING_WEBSITE_SITE_NAME ?
        // cast currently needed, remove after fix for https://github.com/Azure/azure-sdk-for-node/issues/3778 is released
        msRestAzure.loginWithAppServiceMSI({resource: 'https://vault.azure.net'} as msRestAzure.MSIAppServiceOptions) :
        msRestAzure.interactiveLogin();
    const client = new KeyVaultClient(await cred);
    const secret = await client.getSecret(process.env.KEYVAULT_URI!, 'iotHubConnectionString', '');
    if (secret.value === undefined) {
        throw new Error('Found no connection string in key vault');
    } else {
        return secret.value;
    }
}

export async function run(context: HttpContext, req: IFunctionRequest): Promise<void> {
    if (req.query.on === undefined && req.query.off === undefined) {
        context.res = {
            status: 404,
            body: 'missing on or off query string'
        };

        return;
    }
    const connectionString = await getConnectionString();
    const client = Client.fromConnectionString(connectionString);

    // remove promisify, after https://github.com/Azure/azure-sdk-for-node/issues/3369
    // and https://github.com/Azure/azure-iot-sdk-node/issues/362 are solved
    // (planed by 22102018 (https://github.com/Azure/azure-sdk-for-node/milestone/35)
    const invokeDeviceMethod = promisify<string, DeviceMethodParams, any>((d, p, cb: any) =>
        client.invokeDeviceMethod(d, p, cb));

    const methodParams = {
        methodName: req.query.off !== undefined ? 'onSwitchOff' : 'onSwitchOn'
    };
    try {
        const result = await invokeDeviceMethod(deviceId, methodParams);

        context.res = {
            status: result.status,
            body: result.payload
        };
    } catch (err) {
        context.log.error(`Failed to invoke method "${methodParams.methodName}" with error: "${err.message}"`, err);
        context.res = {
            status: 500,
            body: 'Failed to invoke method'
        };
    }
  }
