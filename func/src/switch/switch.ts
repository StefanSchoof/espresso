import { HttpContext, IFunctionRequest } from 'azure-functions-typescript';
import * as msRestAzure from 'ms-rest-azure';
import { KeyVaultClient } from 'azure-keyvault';
import { Client, DeviceMethodParams } from 'azure-iothub';
import { promisify } from 'util';

const deviceId = 'espressoPi';

export async function getConnectionString(): Promise<string> {
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
