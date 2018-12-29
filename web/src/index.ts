import { ApplicationInsights } from "@microsoft/applicationinsights-web";

declare const instrumentationKey: string;

const appInsights = new ApplicationInsights({
    config: {
       disableFetchTracking: false,
       enableCorsCorrelation: true,
       instrumentationKey,
    },
    // needed for beta8, see https://github.com/Microsoft/ApplicationInsights-JS/issues/741
    queue: [],
});

// Gives an error => need to investigate
// appInsights.trackPageView({name: "index"});

import { init } from "./main";
init();
