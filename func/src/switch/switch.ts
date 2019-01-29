import { HttpContext, IFunctionRequest } from "azure-functions-typescript";
import { Client } from "azure-iothub";
import { KeyVaultClient } from "azure-keyvault";
import * as msRestAzure from "ms-rest-azure";

const deviceId = "espressoPi";

async function getConnectionString(): Promise<string> {
    const cred = process.env.APPSETTING_WEBSITE_SITE_NAME ?
        msRestAzure.loginWithAppServiceMSI({resource: "https://vault.azure.net"}) :
        msRestAzure.interactiveLogin();
    const client = new KeyVaultClient(await cred);
    const secret = await client.getSecret(process.env.KEYVAULT_URI!, "iotHubConnectionString", "");
    if (secret.value === undefined) {
        throw new Error("Found no connection string in key vault");
    } else {
        return secret.value;
    }
}

export async function run(context: HttpContext, req: IFunctionRequest): Promise<void> {
    if (req.query.on === undefined && req.query.off === undefined) {
        context.res = {
            body: "missing on or off query string",
            status: 404,
        };

        return;
    }
    const connectionString = await getConnectionString();
    const client = Client.fromConnectionString(connectionString);

    const methodParams = {
        methodName: req.query.off !== undefined ? "onSwitchOff" : "onSwitchOn",
    };
    try {
        const result = (await client.invokeDeviceMethod(deviceId, methodParams)).result;

        context.res = {
            body: result.payload,
            status: result.status,
        };
    } catch (err) {
        context.log.error(`Failed to invoke method "${methodParams.methodName}" with error: "${err.message}"`, err);
        context.res = {
            body: "Failed to invoke method",
            status: 500,
        };
    }
  }
