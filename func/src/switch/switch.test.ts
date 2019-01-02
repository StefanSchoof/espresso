import { HttpContext, IFunctionRequest } from "azure-functions-typescript";
import { Client } from "azure-iothub";
import { KeyVaultClient } from "azure-keyvault";
import * as msRestAzure from "ms-rest-azure";
import { run } from "./switch";

jest.mock("azure-keyvault");
jest.mock("ms-rest-azure");
jest.mock("azure-iothub");

// tslint:disable-next-line:no-empty
function log(...args: any[]): void {
}
// tslint:disable-next-line:no-namespace
namespace log {
  export let warn = jest.fn();
  export let error = jest.fn();
  export let info = jest.fn();
  export let verbose = jest.fn();
}

const context: HttpContext = {res: {status: 0, body: ""}, invocationId: "id", log, bindingData: {}, bindings: {}, done: jest.fn()};

const getSecret = jest.fn(() => Promise.resolve({value: "abc"}));
(KeyVaultClient as jest.Mock<KeyVaultClient>).mockImplementation(() => ({
  getSecret,
}));

const invokeDeviceMethod = jest.fn((a, b, cb) => cb(undefined, {status: 200, paylod: "Hello"}));
Client.fromConnectionString = jest.fn(() => ({
  invokeDeviceMethod,
}));

test("get connection string from keyvault", async () => {
  process.env.KEYVAULT_URI = "https://somevault.vault.azure.net/";
  await run(context, {method: "POST", query: {off: ""}} as any);

  expect(msRestAzure.interactiveLogin)
    .toHaveBeenCalled();
  expect(getSecret)
    .toHaveBeenCalledWith("https://somevault.vault.azure.net/", "iotHubConnectionString", "");
});

test("throws if no keyvault value is found", async () => {
  getSecret.mockImplementationOnce(async () => ({}));

  await expect(run(context, {method: "POST", query: {off: ""}} as any)).rejects
    .toEqual(new Error("Found no connection string in key vault"));
});

test("send off to function switches device off", async () => {
  await run(context, {method: "POST", query: {off: ""} } as any);

  expect(invokeDeviceMethod)
    .toHaveBeenCalledWith("espressoPi", {methodName: "onSwitchOff"}, expect.anything());
  expect(context.res.status)
    .toBe(200);
});

test("send on to function switches device on", async () => {
  await run(context, {method: "POST", query: {on: ""} } as any);

  expect(invokeDeviceMethod)
    .toHaveBeenCalledWith("espressoPi", {methodName: "onSwitchOn"}, expect.anything());
  expect(context.res.status)
    .toBe(200);
});

test("send no parameter returns error", async () => {
  await run(context, {method: "POST", query: {} } as any);

  expect(context.res.status)
    .toBe(404);
});

test("log error invokation error", async () => {
  invokeDeviceMethod.mockImplementationOnce((a, b, cb) => cb(new Error("Some Invokation Error")));

  await run(context, {method: "POST", query: {off: ""} } as any);

  expect(context.log.error)
    .toHaveBeenCalledWith('Failed to invoke method "onSwitchOff" with error: "Some Invokation Error"', expect.anything());
});

test("returns error on Invokation Error", async () => {
  invokeDeviceMethod.mockImplementationOnce((a, b, cb) => cb(new Error("Some Invokation Error")));

  await run(context, {method: "POST", query: {off: ""} } as any);

  expect(context.res.status)
    .toBe(500);
  expect(context.res.body)
    .toBe("Failed to invoke method");
});
