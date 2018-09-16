import { Client } from "azure-iot-device"
import { exec } from "child_process"

const mockDeviceMethods = {}

jest.mock("child_process", () => ({exec: jest.fn()}))
jest.mock("azure-iot-device", () => ({
  Client: {
    fromConnectionString: () => ({
      onDeviceMethod: jest.fn((method, cb) => mockDeviceMethods[method] = cb)
    })
  }
}))

require("./index")

test('on switch on the on cmd is called', () => { 
  mockDeviceMethods.onSwitchOff()
  expect(exec).toHaveBeenCalledWith("steuerung 0", expect.any(Function))
});

test('on switch off the on cmd is called', () => {
  mockDeviceMethods.onSwitchOn() 
  expect(exec).toHaveBeenCalledWith("steuerung 1", expect.any(Function))
});
