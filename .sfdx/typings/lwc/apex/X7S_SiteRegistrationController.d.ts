declare module "@salesforce/apex/X7S_SiteRegistrationController.getStates" {
  export default function getStates(): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.getProvinces" {
  export default function getProvinces(): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.getCountries" {
  export default function getCountries(): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.getPhoneTypes" {
  export default function getPhoneTypes(): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.validateUsername" {
  export default function validateUsername(param: {username: any}): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.validatePassword" {
  export default function validatePassword(param: {password: any}): Promise<any>;
}
declare module "@salesforce/apex/X7S_SiteRegistrationController.registerNewUser" {
  export default function registerNewUser(param: {firstName: any, lastName: any, email: any, password: any, acceptCommunityTerms: any, phoneType: any, phoneNumber: any, streetAddress: any, country: any, postalCode: any, city: any, state: any, domain: any}): Promise<any>;
}
