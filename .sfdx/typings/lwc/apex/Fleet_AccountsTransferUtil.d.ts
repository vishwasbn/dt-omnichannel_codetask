declare module "@salesforce/apex/Fleet_AccountsTransferUtil.search" {
  export default function search(param: {objectName: any, fields: any, searchTerm: any, lbl: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_AccountsTransferUtil.transferAccountsOwnership" {
  export default function transferAccountsOwnership(param: {oldOwner: any, newOwner: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_AccountsTransferUtil.getJobStatus" {
  export default function getJobStatus(param: {jobId: any}): Promise<any>;
}
