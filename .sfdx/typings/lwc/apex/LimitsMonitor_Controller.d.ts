declare module "@salesforce/apex/LimitsMonitor_Controller.scheduleAlert" {
  export default function scheduleAlert(param: {percent: any, schedTime: any, email: any}): Promise<any>;
}
declare module "@salesforce/apex/LimitsMonitor_Controller.getOrgLimits" {
  export default function getOrgLimits(): Promise<any>;
}
declare module "@salesforce/apex/LimitsMonitor_Controller.getObjectLimit" {
  export default function getObjectLimit(param: {apiName: any}): Promise<any>;
}
declare module "@salesforce/apex/LimitsMonitor_Controller.getObjectInfo" {
  export default function getObjectInfo(): Promise<any>;
}
