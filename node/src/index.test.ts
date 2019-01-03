import * as appInsights from "applicationinsights";
import { results } from "azure-iot-common";
import { Client } from "azure-iot-device";
import { exec } from "child_process";

const mockDeviceMethods: {[id: string]: (request: any, response: any) => void} = {};
const mockDeviceEvents: {[id: string]: (listener: any) => void} = {};

jest.mock("child_process", () => ({exec: jest.fn((cmd, cb) => cb())}));
jest.mock("azure-iot-device", () => ({
  Client: {
    fromConnectionString: jest.fn(() => ({
      on: jest.fn((name, cb) => mockDeviceEvents[name] = cb),
      onDeviceMethod: jest.fn((method, cb) => mockDeviceMethods[method] = cb),
    })),
  },
}));

import { init } from "./index";
init("");

describe("index", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("throws on empty connectionString", () => {
    expect(() => init(undefined))
      .toThrow();
  });

  test("use connection string for iot connection", () => {
    init("abc");

    expect(Client.fromConnectionString)
      .toHaveBeenLastCalledWith("abc", expect.anything());
  });

  test("on switch on the on cmd is called", async () => {
    const response = {
      send: jest.fn((code, payload) => Promise.resolve()),
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(exec)
      .toHaveBeenCalledWith("steuerung 0", expect.any(Function));
    expect(response.send)
      .toHaveBeenLastCalledWith(200, expect.anything());
  });

  test("on switch off the on cmd is called", async () => {
    const response = {
      send: jest.fn((code, payload) => Promise.resolve()),
    };

    await mockDeviceMethods.onSwitchOn({}, response);

    expect(exec)
      .toHaveBeenCalledWith("steuerung 1", expect.any(Function));
    expect(response.send)
      .toHaveBeenLastCalledWith(200, expect.anything());
  });

  test("use testing cmd if given", async () => {
    const response = {
      send: jest.fn((code, payload) => Promise.resolve()),
    };
    init("abc", "echo");

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(exec)
      .toHaveBeenCalledWith("echo 0", expect.any(Function));
  });

  test("use normal cmd if empty testingcmd is given", async () => {
    const response = {
      send: jest.fn((code, payload) => Promise.resolve()),
    };
    init("abc", "");

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(exec)
      .toHaveBeenCalledWith("steuerung 0", expect.any(Function));
  });

  test("return an error if exec fails", async () => {
    const response = {
      send: jest.fn((code, payload) => Promise.resolve()),
    };
    (exec as any as jest.Mock<any>)
      .mockImplementationOnce((cmd, cb) => cb(new Error("Command failed")));

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(response.send)
      .toHaveBeenLastCalledWith(500, expect.anything());
    expect(appInsights.defaultClient.trackException)
      .toHaveBeenLastCalledWith({exception: new Error("Command failed")});
  });

  test("log an error if response fails", async () => {
    const e = new Error("Send response failed");
    const response = {
      send: jest.fn((code, payload) => Promise.reject(e)),
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(appInsights.defaultClient.trackException)
      .toHaveBeenLastCalledWith({exception: new Error("Send response failed")});
  });

  test("track request on respose error", async () => {
    const e = new Error("Send response failed");
    const response = {
      send: jest.fn((code, payload) => Promise.reject(e)),
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(appInsights.defaultClient.trackRequest)
    .toHaveBeenLastCalledWith({
        duration: expect.anything(),
        name: "steuerung 0",
        resultCode: 200,
        success: true,
        url: "mqtts://espresso/0",
      });
  });

  test("log on disconnect", async () => {
    mockDeviceEvents.disconnect(new results.Disconnected(new Error("disconnect")));

    expect(appInsights.defaultClient.trackException)
      .toHaveBeenLastCalledWith({exception: new Error("disconnect")});
  });
});
