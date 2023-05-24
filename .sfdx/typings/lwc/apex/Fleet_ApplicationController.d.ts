declare module "@salesforce/apex/Fleet_ApplicationController.saveOrSubmitFleetApplication" {
  export default function saveOrSubmitFleetApplication(param: {fA: any, appStatus: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_ApplicationController.retrieveFleetAppByGUID" {
  export default function retrieveFleetAppByGUID(param: {guid: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_ApplicationController.insertFleetAppAttachments" {
  export default function insertFleetAppAttachments(param: {accountId: any, fleetAppId: any, files: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_ApplicationController.removeFile" {
  export default function removeFile(param: {fleetAppId: any, attachmentType: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_ApplicationController.insertCreditAppReferences" {
  export default function insertCreditAppReferences(param: {fleetAppId: any, references: any}): Promise<any>;
}
