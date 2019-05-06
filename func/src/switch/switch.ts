import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { Client } from "azure-iothub";

const deviceId = "espressoPi";

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    if (req.query.on === undefined && req.query.off === undefined) {
        context.res = {
            body: "missing on or off query string",
            status: 404,
        };

        return;
    }
    if (!process.env.APPSETTING_IOTHUB_CONNECTION_STRING) {
        throw new Error("Found no connection string in key vault");
    }
    const client = Client.fromConnectionString(process.env.APPSETTING_IOTHUB_CONNECTION_STRING);

    const methodParams = {
        methodName: req.query.off !== undefined ? "onSwitchOff" : "onSwitchOn",
    };
    try {
        const result = await client.invokeDeviceMethod(deviceId, methodParams);

        context.res = {
            body: result.result.payload,
            status: result.result.status,
        };
    } catch (err) {
        context.log.error(`Failed to invoke method "${methodParams.methodName}" with error: "${err.message}"`, err);
        context.res = {
            body: "Failed to invoke method",
            status: 500,
        };
    }
}

export default httpTrigger;
