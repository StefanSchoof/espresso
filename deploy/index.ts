import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as fs from "fs";
import * as terraform_template from "@pulumi/terraform-template";

const stage = ((pulumi.getStack() === "prod") ? "" : pulumi.getStack());
const current = pulumi.output(azure.core.getClientConfig({}));
const cloudInit = pulumi.output(terraform_template.getFile({
    template: fs.readFileSync(`./cloud-config.txt`, "utf-8"),
}));
const group = new azure.core.ResourceGroup("group", {
    location: "West Europe",
    name: `espresso${stage}`,
});
const westEuropePlan = new azure.appservice.Plan("WestEuropePlan", {
    kind: "functionapp",
    location: group.location,
    name: "WestEuropePlan",
    resourceGroupName: group.name,
    sku: {
        size: "Y1",
        tier: "Dynamic",
    },
});
const functionInsights = new azure.appinsights.Insights("function", {
    applicationType: "web",
    location: group.location,
    name: `espressoPi${stage}`,
    resourceGroupName: group.name,
});
const node = new azure.appinsights.Insights("node", {
    applicationType: "Node.JS",
    location: group.location,
    name: `espresso${stage}-node`,
    resourceGroupName: group.name,
});
const web = new azure.appinsights.Insights("web", {
    applicationType: "web",
    location: group.location,
    name: `espresso${stage}-web`,
    resourceGroupName: group.name,
});
const iothubIoTHub = new azure.iot.IoTHub("iothub", {
    location: group.location,
    name: `espresso${stage}`,
    resourceGroupName: group.name,
    sku: {
        capacity: 1,
        name: ((pulumi.getStack() === "prod") ? "F1" : "S1"),
        tier: ((pulumi.getStack() === "prod") ? "Free" : "Standard"),
    },
});
const keyvault = new azure.keyvault.KeyVault("keyvault", {
    location: group.location,
    name: `espresso${stage}Vault`,
    resourceGroupName: group.name,
    sku: {
        name: "standard",
    },
    tenantId: current.apply(current => current.tenantId),
});
const service = new azure.keyvault.AccessPolicy("service", {
    keyPermissions: [],
    keyVaultId: keyvault.id,
    objectId: current.apply(current => current.servicePrincipalObjectId),
    secretPermissions: [
        "get",
        "set",
        "list",
        "delete",
    ],
    tenantId: current.apply(current => current.tenantId),
});
const iotHubConnectionString = new azure.keyvault.Secret("iotHubConnectionString", {
    keyVaultId: keyvault.id,
    name: "iotHubConnectionString",
    value: pulumi.all([iothubIoTHub.hostname, iothubIoTHub.sharedAccessPolicies, iothubIoTHub.sharedAccessPolicies]).apply(([hostname, iothubIoTHubSharedAccessPolicies, iothubIoTHubSharedAccessPolicies1]) => `HostName=${hostname};SharedAccessKeyName=${iothubIoTHubSharedAccessPolicies[0].keyName};SharedAccessKey=${iothubIoTHubSharedAccessPolicies1[0].primaryKey}`),
}, {dependsOn: [service]});
const storage = new azure.storage.Account("storage", {
    accountKind: "StorageV2",
    accountReplicationType: "LRS",
    accountTier: "Standard",
    location: group.location,
    name: `espressopi${stage}`,
    resourceGroupName: group.name,
});
const functionFunctionApp = new azure.appservice.FunctionApp("function", {
    appServicePlanId: westEuropePlan.id,
    appSettings: {
        APPINSIGHTS_INSTRUMENTATIONKEY: functionInsights.instrumentationKey,
        IOTHUB_CONNECTION_STRING: iotHubConnectionString.id.apply(id => `@Microsoft.KeyVault(SecretUri=${id})`),
        WEBSITE_NODE_DEFAULT_VERSION: "10.14.1",
        WEBSITE_RUN_FROM_PACKAGE: "1",
    },
    identity: {
        type: "SystemAssigned",
    },
    location: group.location,
    name: `espressoPi${stage}`,
    resourceGroupName: group.name,
    storageConnectionString: storage.primaryConnectionString,
    version: "~2",
});
const app = new azure.keyvault.AccessPolicy("app", {
    keyPermissions: [],
    keyVaultId: keyvault.id,
    objectId: functionFunctionApp.identity.apply(identity => identity.principalId),
    secretPermissions: ["get"],
    tenantId: functionFunctionApp.identity.apply(identity => identity.tenantId),
});
const ip: azure.network.PublicIp[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    ip.push(new azure.network.PublicIp(`ip-${i}`, {
        allocationMethod: "Dynamic",
        domainNameLabel: "espresso",
        idleTimeoutInMinutes: 30,
        location: group.location,
        name: "dockerhost-ip",
        resourceGroupName: group.name,
    }));
}
const network: azure.network.VirtualNetwork[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    network.push(new azure.network.VirtualNetwork(`network-${i}`, {
        addressSpaces: ["10.1.0.0/24"],
        location: group.location,
        name: "dockerhost-vnet",
        resourceGroupName: group.name,
    }));
}
const defaultSubnet: azure.network.Subnet[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    defaultSubnet.push(new azure.network.Subnet(`default-${i}`, {
        addressPrefix: "10.1.0.0/24",
        name: "default",
        resourceGroupName: group.name,
        virtualNetworkName: network[0].name,
    }));
}
const nic: azure.network.NetworkInterface[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    nic.push(new azure.network.NetworkInterface(`nic-${i}`, {
        ipConfigurations: [{
            name: "ipconfig1",
            privateIpAddressAllocation: "dynamic",
            publicIpAddressId: ip[0].id,
            subnetId: defaultSubnet[0].id,
        }],
        location: group.location,
        name: "dockerhost-nic",
        resourceGroupName: group.name,
    }));
}
const config = cloudInit.apply(cloudInit => terraform_template.getCloudInitConfig({
    parts: [
        {
            content: "https://get.docker.com",
            contentType: "text/x-include-url",
        },
        {
            content: cloudInit.rendered,
            contentType: "text/cloud-config",
        },
    ],
}));
const dockerhost: azure.compute.VirtualMachine[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    dockerhost.push(new azure.compute.VirtualMachine(`dockerhost-${i}`, {
        deleteDataDisksOnTermination: true,
        deleteOsDiskOnTermination: true,
        location: group.location,
        name: "dockerhost-vm",
        networkInterfaceIds: [nic[0].id],
        osProfile: {
            adminUsername: "dockeradmin",
            computerName: "dockerhost",
            customData: config.apply(config => config.rendered),
        },
        osProfileLinuxConfig: {
            disablePasswordAuthentication: true,
            sshKeys: [{
                keyData: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9QKIJL4OygWMvTzvsi9zC03R/t5riw4SfLg3+EqfM79Bex0ChBdqx6i2ddhkmkfGwFXm/Si2cEM2WVcjNWCgbTgKaJDGVANnCz4zlxqsUAEE2izzMLD+vLqSz7OAn/xAiMv0w0mNevmleFLPwgRyXCq7TRzl+b83/DJD6R4YIHeqsnCRkqCmh+FGJL9SF0u+gIdl8/a4L0XLTz2nvWVrFWPfP4bn5f6GCKpKuaHwa9dxyGlQRo1xYviE5nRZjxVfY4cBvahkBJFxc26iRVDgdyqk/iTPVosN2qNDQ3/Yt2106UqRmLi9ssW6hiFr2Ejoq3JJd6Tq8V2QRVU45OQEV sschoof@sdhamw057",
                path: "/home/dockeradmin/.ssh/authorized_keys",
            }],
        },
        resourceGroupName: group.name,
        storageImageReference: {
            offer: "UbuntuServer",
            publisher: "Canonical",
            sku: "18.04-LTS",
            version: "latest",
        },
        storageOsDisk: {
            caching: "ReadWrite",
            createOption: "FromImage",
            managedDiskType: "Standard_LRS",
            name: "dockerhostosdisk",
        },
        vmSize: "Standard_DS1_v2",
    }));
}
const cloudinitwait: azure.compute.Extension[] = [];
for (let i = 0; i < ((pulumi.getStack() === "prod") ? 0 : 1); i++) {
    cloudinitwait.push(new azure.compute.Extension(`cloudinitwait-${i}`, {
        location: group.location,
        name: "cloudinitwait",
        publisher: "Microsoft.Azure.Extensions",
        resourceGroupName: group.name,
        settings: `    {
        "commandToExecute": "cloud-init status --wait"
    }
`,
        type: "CustomScript",
        typeHandlerVersion: "2.0",
        virtualMachineName: dockerhost[0].name,
    }));
}

export const azurermApplicationInsightsNode = {
    sensitive: true,
    value: node.instrumentationKey,
};
export const azurermApplicationInsightsWeb = {
    sensitive: true,
    value: web.instrumentationKey,
};
export const functionApp = functionFunctionApp.name;
export const functionAppHostname = functionFunctionApp.defaultHostname;
export const iothub = iothubIoTHub.name;
export const publicFqdnAddress = ip.map(v => v.fqdn);
export const resourceGroup = group.name;
export const storageAccount = storage.name;
