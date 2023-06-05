declare module "@salesforce/apex/Fleet_AccountApprovalController.getAccount" {
  export default function getAccount(param: {Id: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_AccountApprovalController.approveAccount" {
  export default function approveAccount(param: {accountId: any, modifiedAcctString: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_AccountApprovalController.declineFleetApplication" {
  export default function declineFleetApplication(param: {accountId: any}): Promise<any>;
}
