import { AppInsights } from "applicationinsights-js";

AppInsights.downloadAndSetup!({
    // Currently defaults to true, see https://github.com/Microsoft/ApplicationInsights-JS/issues/395
    disableCorrelationHeaders: false,
    enableCorsCorrelation: true,
    instrumentationKey: "9e4a7c64-7254-48a4-98e1-9879dad52f11",
});

// add support for fetch, see https://github.com/Microsoft/ApplicationInsights-JS/issues/625
import { initAppInsightsFetchMonitor } from "application-insights-fetch-monitor";
initAppInsightsFetchMonitor();

AppInsights.trackPageView();

import { init } from "./main";
init();
