import { AppInsights } from "applicationinsights-js";

declare const instrumentationKey: string;

AppInsights.downloadAndSetup!({
    // Currently defaults to true, see https://github.com/Microsoft/ApplicationInsights-JS/issues/395
    disableCorrelationHeaders: false,
    enableCorsCorrelation: true,
    instrumentationKey,
});

// add support for fetch, see https://github.com/Microsoft/ApplicationInsights-JS/issues/625
import { initAppInsightsFetchMonitor } from "application-insights-fetch-monitor";
initAppInsightsFetchMonitor();

AppInsights.trackPageView();

import { init } from "./main";
init();
