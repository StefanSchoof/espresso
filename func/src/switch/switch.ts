import { Context, HttpRequest } from 'azure-functions-ts-essentials';

export async function run(context: Context, req: HttpRequest): Promise<void> {
    context.res = {
        status: 200,
        body: 'Hello World'
    };
  }
