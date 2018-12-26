import * as msRestAzure from 'ms-rest-azure';
import { KeyVaultClient } from 'azure-keyvault';


export async function getConnectionString(): Promise<string> {
    const cred = msRestAzure.loginWithAppServiceMSI({resource: 'https://vault.azure.net'} as msRestAzure.MSIAppServiceOptions);
    const client = new KeyVaultClient(await cred);
    const secret = await client.getSecret(process.env.KEYVAULT_URI!, 'iotHubConnectionString', '');
    return secret.value;
}
