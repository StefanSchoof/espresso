import { HttpContext } from "azure-functions-typescript";
import { Client } from "azure-iothub";
import { run } from "./switch";

jest.mock("azure-iothub");

const log = jest.fn() as unknown as HttpContext["log"];
log.warn = jest.fn();
log.error = jest.fn();
log.info = jest.fn();
log.verbose = jest.fn();

const context: HttpContext = {
    bindingData: {},
    bindings: {},
    done: jest.fn(),
    invocationId: "id",
    log,
    res: {status: 0, body: ""},
};

const invokeDeviceMethod = jest.fn(() => Promise.resolve({result: {status: 200, paylod: "Hello"}}));
Client.fromConnectionString = jest.fn(() => ({
    invokeDeviceMethod,
} as any));

beforeEach(() => {
    process.env.APPSETTING_IOTHUB_CONNECTION_STRING = "https://myvault.x/a/123";
});

test("throws if no iothub connection string is found", async () => {
    delete process.env.APPSETTING_IOTHUB_CONNECTION_STRING;

    await expect(run(context, {method: "POST", query: {off: ""}} as any)).rejects
        .toEqual(new Error("Found no connection string in key vault"));
});

test("send off to function switches device off", async () => {
    await run(context, {method: "POST", query: {off: ""} } as any);

    expect(invokeDeviceMethod)
        .toHaveBeenCalledWith("espressoPi", {methodName: "onSwitchOff"});
    expect(context.res.status)
        .toBe(200);
});

test("send on to function switches device on", async () => {
    await run(context, {method: "POST", query: {on: ""} } as any);

    expect(invokeDeviceMethod)
        .toHaveBeenCalledWith("espressoPi", {methodName: "onSwitchOn"});
    expect(context.res.status)
        .toBe(200);
});

test("send no parameter returns error", async () => {
    await run(context, {method: "POST", query: {} } as any);

    expect(context.res.status)
        .toBe(404);
});

test("log error invokation error", async () => {
    invokeDeviceMethod.mockImplementationOnce(() => Promise.reject(new Error("Some Invokation Error")));

    await run(context, {method: "POST", query: {off: ""} } as any);

    expect(context.log.error)
        .toHaveBeenCalledWith(
            'Failed to invoke method "onSwitchOff" with error: "Some Invokation Error"', expect.anything());
});

test("returns error on Invokation Error", async () => {
    invokeDeviceMethod.mockImplementationOnce(() => Promise.reject(new Error("Some Invokation Error")));

    await run(context, {method: "POST", query: {off: ""} } as any);

    expect(context.res.status)
        .toBe(500);
    expect(context.res.body)
        .toBe("Failed to invoke method");
});
