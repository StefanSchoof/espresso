import { Client } from 'azure-iot-device';
import { exec } from 'child_process';
import * as appInsights from 'applicationinsights';

const mockDeviceMethods: {[id: string]: Function} = {};

jest.mock('child_process', () => ({exec: jest.fn((cmd, cb) => cb())}));
jest.mock('azure-iot-device', () => ({
  Client: {
    fromConnectionString: jest.fn(() => ({
      onDeviceMethod: jest.fn((method, cb) => mockDeviceMethods[method] = cb)
    }))
  }
}));

import { init } from './index';
init('');

describe('index', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('throws on empty connectionString', () => {
    expect(() => init(undefined))
      .toThrow();
  });

  test('use connection string for iot connection', () => {
    init('abc');

    expect(Client.fromConnectionString)
      .toHaveBeenLastCalledWith('abc', expect.anything());
  });

  test('on switch on the on cmd is called', async () => {
    const response = {
      send: jest.fn((code, payload, done) => done())
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(exec)
      .toHaveBeenCalledWith('steuerung 0', expect.any(Function));
    expect(response.send)
      .toHaveBeenLastCalledWith(200, expect.anything(), expect.anything());
  });

  test('on switch off the on cmd is called', async () => {
    const response = {
      send: jest.fn((code, payload, done) => done())
    };

    await mockDeviceMethods.onSwitchOn({}, response);

    expect(exec)
      .toHaveBeenCalledWith('steuerung 1', expect.any(Function));
    expect(response.send)
      .toHaveBeenLastCalledWith(200, expect.anything(), expect.anything());
  });

  test('return an error if exec fails', async () => {
    const response = {
      send: jest.fn((code, payload, done) => done())
    };
    (exec as any as jest.Mock<any>)
      .mockImplementationOnce((cmd, cb) => cb(new Error('Command failed')));

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(response.send)
      .toHaveBeenLastCalledWith(500, expect.anything(), expect.anything());
    expect(appInsights.defaultClient.trackException)
      .toHaveBeenLastCalledWith({exception: new Error('Command failed')});
  });

  test('log an error if response fails', async () => {
    const e = new Error('Send response failed');
    const response = {
      send: jest.fn((code, payload, done) => done(e))
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(appInsights.defaultClient.trackException)
      .toHaveBeenLastCalledWith({exception: new Error('Send response failed')});
  });

  test('does not destroy context in response send', async () => {
    const response = {
      isResponseComplete: false,
      send: jest.fn(function(this: any, code: any, payload: any, done: any): void {
        if (!this.isResponseComplete) {
          done();
        }
      })
    };

    await expect(mockDeviceMethods.onSwitchOff({}, response))
      .resolves
      .toBe(undefined);
  });

  test('track request on respose error', async () => {
    const e = new Error('Send response failed');
    const response = {
      send: jest.fn((code, payload, done) => done(e))
    };

    await mockDeviceMethods.onSwitchOff({}, response);

    expect(appInsights.defaultClient.trackRequest)
      .toHaveBeenLastCalledWith({
        url: 'mqtts://espresso/0',
        name: 'steuerung 0',
        duration: expect.anything(),
        resultCode: 200,
        success: true});
  });
});
