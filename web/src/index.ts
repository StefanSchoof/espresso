declare const instrumentationKey: string;
declare const functionsCode: string;
declare const functionsHostname: string;

import { init } from "./main";
init(functionsHostname, functionsCode, instrumentationKey);
