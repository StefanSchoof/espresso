import { run } from './switch';
import { Context, HttpMethod } from 'azure-functions-ts-essentials';

test('returns Hello World', async () => {
    const context = {res: {status: 0, body: ''}} as Context;

    await run(context, {method: HttpMethod.Get});

    expect(context.res)
      .not
      .toBeNull();
    expect(context.res!.body)
      .toBe('Hello World');
  });
