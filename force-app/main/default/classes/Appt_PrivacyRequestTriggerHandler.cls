public class Appt_PrivacyRequestTriggerHandler {

    public static String lprefix = 'LOG_PrivReqTH:';
    private static final String SCRAMBLED_TEXT = '<scrambled>';
    private static final String SCRAMBLED_PHONE = '9999999999';
    private static final String SCRAMBLED_EMAIL = 'scrambled@scrambled.com';

    //---Primary Privacy_Request__c Trigger Handler for Appointment
    public static void handle(Map<Id, Privacy_Request__c> oldMap, Map<Id, Privacy_Request__c> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Appt PrivacyRequestTrigger Handler - START');

        switch on triggerEvent 
        {
            when AFTER_INSERT {
                System.debug( lprefix + 'Appt PrivacyRequestTrigger AFTER_INSERT');
                processPrivacyRequest(oldMap, newMap);
            }
            when BEFORE_UPDATE {
                //do nothing   
            }
            when AFTER_UPDATE {
                System.debug( lprefix + 'Appt PrivacyRequestTrigger AFTER_UPDATE');
                processPrivacyRequest(oldMap, newMap);
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Appt PrivacyRequestTrigger Handler - END');
    }

    private static void processPrivacyRequest(Map<Id, Privacy_Request__c> oldMap, Map<Id, Privacy_Request__c> newMap) {
        System.debug( lprefix + 'processPrivacyRequest() - ENTRY');

        List<Id> privacyAccountIdList = new List<Id>();

        //-- loop through Privacy_Request__c records and if confirmed, add to list of Account Ids
        for (Privacy_Request__c privReq: newMap.values()) {
            if (privReq.Confirmed__c == true) privacyAccountIdList.add(privReq.Account__c);
        }

        if (privacyAccountIdList.size() > 0) {

            Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

            //-- Get the Account records for the Account Ids
            List<Account> privacyAccountList = getAccounts(privacyAccountIdList, personAccountRecordTypeId);

            //-- Commenting out since all contact fields are access through Person Account
            //List<Contact> privacyContactList = getContacts(privacyAccountIdList, personAccountRecordTypeId);

            //--get the vehicle Asset records for the Account Ids
            List<Asset> privacyAssetList = getAssets(privacyAccountIdList, personAccountRecordTypeId);

            //-- get the Notification record Ids for the Account Ids. Only need Ids because the records will be deleted.
            List<Notification__c> privacyNotificationIdList = getNotificationIds(privacyAccountIdList, personAccountRecordTypeId);

            //-- get the WorkOrders for the Account Ids so that SMS_Phone can be set to null. SMS_Phone is only PII field on WO
            List<WorkOrder> privacyWorkOrderList = getWorkOrders(privacyAccountIdList);

            //--Scramble the PII fields on each List of records, except for List<Notification__c> which will be deleted
            scrambleAccounts(privacyAccountList);
            //scrambleContacts(privacyContactList);
            scrambleAssets(privacyAssetList);
            scrambleWorkOrders(privacyWorkOrderList);

            //-- delete the Notifications
            if (privacyNotificationIdList!= null) {
                System.debug( lprefix + '     ABOUT TO DELETE privacyNotificationIdList with '+privacyNotificationIdList.size()+' items');
                delete privacyNotificationIdList;
                System.debug( lprefix + '     successfully DELETED privacyNotificationIdList');
            }

            //-- update the Lists of records
            if (privacyAccountList != null) {
                System.debug( lprefix + '     ABOUT TO UPDATE privacyAccountList with '+privacyAccountList.size()+' items');
                update privacyAccountList;
                System.debug( lprefix + '     successfully UPDATED privacyAccountList');
            }

            //-- Commenting out since all contact fields are access through Person Account
            // if (privacyContactList != null) {
            //     System.debug( lprefix + '     ABOUT TO UPDATE privacyContactList with '+privacyContactList.size()+' items');
            //     update privacyContactList;
            //     System.debug( lprefix + '     successfully UPDATED privacyContactList');
            // }

            if (privacyAssetList != null) {
                System.debug( lprefix + '     ABOUT TO UPDATE privacyAssetList with '+privacyAssetList.size()+' items');
                update privacyAssetList;
                System.debug( lprefix + '     successfully UPDATED privacyAssetList');
            }

            if (privacyWorkOrderList != null) {
                System.debug( lprefix + '     ABOUT TO UPDATE privacyWorkOrderList with '+privacyWorkOrderList.size()+' items');
                update privacyWorkOrderList;
                System.debug( lprefix + '     successfully UPDATED privacyWorkOrderList');
            }
        }

        System.debug( lprefix + 'processPrivacyRequest() - EXIT');
    }

    private static void scrambleWorkOrders(List<WorkOrder> privacyWorkOrderList) {
        System.debug( lprefix + 'scrambleWorkOrders() ENTRY');
        if (privacyWorkOrderList != null) {
            for (WorkOrder wo: privacyWorkOrderList) {
                wo.SMS_Phone__c = null;
            }
        }
    }

    private static void scrambleAssets(List<Asset> privacyAssetList) {
        System.debug( lprefix + 'scrambleContacts() ENTRY');

        if(privacyAssetList != null) {
            for (Asset veh: privacyAssetList) {
                veh.Name = SCRAMBLED_TEXT;
                veh.Description = SCRAMBLED_TEXT;
                veh.VIN__c = SCRAMBLED_TEXT;
                veh.Vehicle_License_Plate__c = SCRAMBLED_TEXT;
                veh.Vehicle_Make__c = SCRAMBLED_TEXT;
                veh.Vehicle_Model__c = SCRAMBLED_TEXT;
                veh.Vehicle_Year__c = 1776;
                veh.Vehicle_Manufacture_Year__c = '1776';
                veh.Vehicle_Type_Other__c = SCRAMBLED_TEXT;
                veh.Vehicle_Type__c = null;
                veh.Vehicle_Class__c  = SCRAMBLED_TEXT;
            }
        }

        System.debug( lprefix + 'scrambleContacts() ENTRY');
    }

    //-- Commenting out since all contact fields are access through Person Account ----
    // private static void scrambleContacts(List<Contact> privacyContactList) {
    //     System.debug( lprefix + 'scrambleContacts() ENTRY');

    //     if (privacyContactList != null) {
    //         for (Contact cnt: privacyContactList) {
    //             cnt.LastName = SCRAMBLED_TEXT;
    //             cnt.FirstName = SCRAMBLED_TEXT;
    //             cnt.Salutation = SCRAMBLED_TEXT;
    //             cnt.MiddleName = SCRAMBLED_TEXT;
    //             cnt.Suffix = SCRAMBLED_TEXT;
    //             cnt.MailingStreet = SCRAMBLED_TEXT;
    //             cnt.MailingCity = SCRAMBLED_TEXT;
    //             cnt.MailingState = null;
    //             cnt.MailingPostalCode = null;
    //             cnt.MailingCountry = null;
    //             cnt.MailingStateCode = null;
    //             cnt.MailingCountryCode = null;
    //             cnt.MailingLatitude = null;
    //             cnt.MailingLongitude = null;
    //             cnt.MailingGeocodeAccuracy = null;
    //             cnt.Phone = SCRAMBLED_PHONE;
    //             cnt.Fax = SCRAMBLED_PHONE;
    //             cnt.MobilePhone = SCRAMBLED_PHONE;
    //             cnt.Email = SCRAMBLED_EMAIL;
    //             cnt.Title = SCRAMBLED_TEXT;
    //             cnt.Department = SCRAMBLED_TEXT;
    //             cnt.Contact_Notes__c = SCRAMBLED_TEXT;
    //             cnt.Driver_License_Number__c = SCRAMBLED_TEXT;
    //             cnt.Driver_License_State__c = null;
    //             cnt.Preferred_Store__c = null;
    //             cnt.Statement_Invoice_Email__c = SCRAMBLED_EMAIL;
    //             cnt.Appt_Email_Opt_In__c = false;
    //             cnt.Appt_SMS_Opt_In__c = false;
    //         }
    //     }

    //     System.debug( lprefix + 'scrambleContacts() EXIT');
    // }

    private static void scrambleAccounts(List<Account> privacyAccountList) {
        System.debug( lprefix + 'scrambleAccounts() ENTRY');

        if (privacyAccountList != null) {
            for (Account acnt: privacyAccountList) {
                acnt.Name = SCRAMBLED_TEXT; 
                acnt.LastName = SCRAMBLED_TEXT; 
                acnt.FirstName = SCRAMBLED_TEXT; 
                acnt.Salutation = null; 
                acnt.MiddleName = SCRAMBLED_TEXT; 
                acnt.Suffix = SCRAMBLED_TEXT; 
                acnt.Type = 'Other'; 
                acnt.BillingStreet = SCRAMBLED_TEXT; 
                acnt.BillingCity = SCRAMBLED_TEXT; 
                acnt.BillingState = null;
                acnt.BillingPostalCode = null;
                acnt.BillingCountry = null; 
                acnt.BillingStateCode = null;
                acnt.BillingCountryCode = null;
                acnt.BillingLatitude = null;
                acnt.BillingLongitude = null;
                acnt.BillingGeocodeAccuracy = null;
                acnt.ShippingStreet = SCRAMBLED_TEXT; 
                acnt.ShippingCity = SCRAMBLED_TEXT; 
                acnt.ShippingState = null;
                acnt.ShippingPostalCode = null;
                acnt.ShippingCountry = null;
                acnt.ShippingStateCode = null;
                acnt.ShippingCountryCode = null;
                acnt.ShippingLatitude = null;
                acnt.ShippingLongitude = null;
                acnt.ShippingGeocodeAccuracy = null;
                acnt.Phone = SCRAMBLED_PHONE;
                acnt.Website = SCRAMBLED_TEXT;
                acnt.Industry = 'Miscellaneous';
                acnt.NumberOfEmployees = 0;
                acnt.Description = SCRAMBLED_TEXT;
                acnt.PersonMailingStreet = SCRAMBLED_TEXT;
                acnt.PersonMailingCity = SCRAMBLED_TEXT;
                acnt.PersonMailingState = null;
                acnt.PersonMailingPostalCode = null;
                acnt.PersonMailingCountry = null;
                acnt.PersonMailingStateCode = null;
                acnt.PersonMailingCountryCode = null;
                acnt.PersonMailingLatitude = null;
                acnt.PersonMailingLongitude = null;
                acnt.PersonMailingGeocodeAccuracy = null;
                acnt.PersonMobilePhone = SCRAMBLED_PHONE;
                acnt.PersonHomePhone = SCRAMBLED_PHONE;
                acnt.PersonEmail = SCRAMBLED_EMAIL;
                acnt.PersonTitle = SCRAMBLED_TEXT;
                acnt.Email__c = SCRAMBLED_EMAIL;
                acnt.ShippingCounty__c = SCRAMBLED_TEXT;
                acnt.Driver_License_Number__pc = null;
                acnt.Driver_License_State__pc = null;
                acnt.Preferred_Store__pc = null;
                acnt.Statement_Invoice_Email__pc = null;
                acnt.Appt_Email_Opt_In__pc = false;
                acnt.Appt_SMS_Opt_In__pc = false;
                acnt.Contact_Notes__pc = SCRAMBLED_TEXT;
                acnt.PersonDepartment = SCRAMBLED_TEXT;
                acnt.PersonContact.Fax = SCRAMBLED_PHONE;
            }
        }

        System.debug( lprefix + 'scrambleAccounts() EXIT');
    }

    private static List<Account> getAccounts(List<Id> privacyAccountIdList, Id personAccountRecordTypeId) {
        System.debug( lprefix + 'getAccounts() ENTRY - number of account IDs = '+privacyAccountIdList.size());

        return [SELECT Id, Name, LastName, FirstName, Salutation, MiddleName, Suffix, Type, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                BillingStateCode, BillingCountryCode, BillingLatitude, BillingLongitude, BillingGeocodeAccuracy, BillingAddress, ShippingStreet, ShippingCity, ShippingState, 
                ShippingPostalCode, ShippingCountry, ShippingStateCode, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingGeocodeAccuracy, ShippingAddress, PersonContact.Fax, 
                Phone, Website, PhotoUrl, Industry, NumberOfEmployees, Description,  PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, Contact_Notes__pc, 
                PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonMailingStateCode, PersonMailingCountryCode, PersonMailingLatitude, Appt_SMS_Opt_In__pc, 
                PersonMailingLongitude, PersonMailingGeocodeAccuracy, PersonMailingAddress, PersonMobilePhone, PersonHomePhone, PersonEmail, PersonTitle, Email__c, PersonDepartment,
                ShippingCounty__c, Driver_License_Number__pc, Driver_License_State__pc, Preferred_Store__pc, Statement_Invoice_Email__pc, Appt_Email_Opt_In__pc 
                FROM Account WHERE Id IN :privacyAccountIdList AND RecordTypeId = :personAccountRecordTypeId];
    }

    //-- Commenting out since all contact fields are access through Person Account
    // private static List<Contact> getContacts(List<Id> privacyAccountIdList, Id personAccountRecordTypeId) {
    //     System.debug( lprefix + 'getContacts() ENTRY - number of account IDs = '+privacyAccountIdList.size());

    //     return [SELECT Id, AccountId, LastName, FirstName, Salutation, MiddleName, Suffix, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, 
    //             MailingStateCode, MailingCountryCode, MailingLatitude, MailingLongitude, MailingGeocodeAccuracy, MailingAddress, Phone, Fax, MobilePhone, Email, 
    //             Title, Department, Contact_Notes__c, Driver_License_Number__c, Driver_License_State__c, Preferred_Store__c, Statement_Invoice_Email__c, 
    //             Appt_Email_Opt_In__c, Appt_SMS_Opt_In__c 
    //             FROM Contact WHERE AccountId IN :privacyAccountIdList AND Account.RecordTypeId  = :personAccountRecordTypeId];
    // }

    private static List<Asset> getAssets(List<Id> privacyAccountIdList, Id personAccountRecordTypeId) {
        System.debug( lprefix + 'getAssets() ENTRY - number of account IDs = '+privacyAccountIdList.size());

        Id vehicleAssetRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        return [SELECT Id, Name, AccountId, Description, VIN__c, Vehicle_License_Plate__c, Vehicle_Make__c, Vehicle_Model__c, Vehicle_Year__c, Vehicle_Manufacture_Year__c, 
        Vehicle_Number__c, Vehicle_Type_Other__c, Vehicle_Type__c, Vehicle_Class__c 
        FROM Asset WHERE RecordTypeId = :vehicleAssetRecordTypeId AND AccountId IN :privacyAccountIdList AND Account.RecordTypeId  = :personAccountRecordTypeId];
    }

    private static List<Notification__c> getNotificationIds(List<Id> privacyAccountIdList, Id personAccountRecordTypeId) {
        System.debug( lprefix + 'getNotificationIds() ENTRY - number of account IDs = '+privacyAccountIdList.size());

        Id vehicleAssetRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        return [SELECT Id FROM Notification__c WHERE Account__c IN :privacyAccountIdList AND Account__r.RecordTypeId  = :personAccountRecordTypeId];
    }

    private static List<WorkOrder> getWorkOrders(List<Id> privacyAccountIdList) {
        System.debug( lprefix + 'getWorkOrders() ENTRY - number of account IDs = '+privacyAccountIdList.size());

        return [SELECT Id, SMS_Phone__c FROM WorkOrder WHERE AccountId IN :privacyAccountIdList];
    }
}