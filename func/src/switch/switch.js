"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const msRestAzure = __importStar(require("ms-rest-azure"));
const azure_keyvault_1 = require("azure-keyvault");
async function getConnectionString() {
    const cred = msRestAzure.loginWithAppServiceMSI({ resource: 'https://vault.azure.net' });
    const client = new azure_keyvault_1.KeyVaultClient(await cred);
    const secret = await client.getSecret(process.env.KEYVAULT_URI, 'iotHubConnectionString', '');
    return secret.value;
}
exports.getConnectionString = getConnectionString;
