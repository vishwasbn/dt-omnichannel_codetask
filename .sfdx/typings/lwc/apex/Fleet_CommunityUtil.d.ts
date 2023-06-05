declare module "@salesforce/apex/Fleet_CommunityUtil.getAccountIdForCommunityUser" {
  export default function getAccountIdForCommunityUser(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getUserInfo" {
  export default function getUserInfo(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getDriversByAccount" {
  export default function getDriversByAccount(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getVehiclesByAccount" {
  export default function getVehiclesByAccount(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getMyUsersByAccountCached" {
  export default function getMyUsersByAccountCached(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getMyUsersByAccount" {
  export default function getMyUsersByAccount(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getDriverRecordTypeId" {
  export default function getDriverRecordTypeId(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getB2bContactRecordTypeId" {
  export default function getB2bContactRecordTypeId(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getVehicleRecordTypeId" {
  export default function getVehicleRecordTypeId(): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.saveCommunityContact" {
  export default function saveCommunityContact(param: {fields: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.saveCommunityAsset" {
  export default function saveCommunityAsset(param: {fields: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.deleteCommunityAsset" {
  export default function deleteCommunityAsset(param: {vehicleId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.addNoteAsset" {
  export default function addNoteAsset(param: {vehicleId: any, note: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.addNoteContact" {
  export default function addNoteContact(param: {contactId: any, note: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.deleteCommunityContact" {
  export default function deleteCommunityContact(param: {contactId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.resetCommunityUserPassword" {
  export default function resetCommunityUserPassword(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.unlockCommunityUser" {
  export default function unlockCommunityUser(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.checkForLockedUser" {
  export default function checkForLockedUser(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.checkForActiveUser" {
  export default function checkForActiveUser(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.deactivateCommunityUser" {
  export default function deactivateCommunityUser(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.createCommunityUser" {
  export default function createCommunityUser(param: {communityContactString: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.updateCommunityUser" {
  export default function updateCommunityUser(param: {communityUserString: any}): Promise<any>;
}
declare module "@salesforce/apex/Fleet_CommunityUtil.getCommunityUserInfo" {
  export default function getCommunityUserInfo(): Promise<any>;
}
