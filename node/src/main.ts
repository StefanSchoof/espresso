import * as appInsights from 'applicationinsights';
appInsights.setup()
  .start();

import { init } from './index';

init(process.env['ConnectionString']);
