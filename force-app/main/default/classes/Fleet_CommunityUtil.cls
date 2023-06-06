/**
 Created By : Angie.Pilon
 Creatted Dated : 04/05/2022
 Description : This Class is called when record in Inserted,Updated or deleted on the Account Object and to reflect on Community Portal. 
 Modified By : Rohith V
 Modified Date :  09/15/2022
 User Story Number : Salesforce-263.
 */
public without sharing class Fleet_CommunityUtil {

    public static String lprefix = 'FLEET_COMU:';

    // Get account Id
    @AuraEnabled
    public static id getAccountIdForCommunityUser(){   
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix + 'getAccountIdForCommunityUser() ENTRY');

        try{
            User newUser = [SELECT id, accountId FROM USER WHERE id = :UserInfo.getUserId()];
            System.debug(lprefix + 'getAccountIdForCommunityUser() EXIT - Returning accountId = ' + newUser.accountId);
            return newUser.accountId;
        } catch (Exception e) {
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            System.debug(lprefix + 'getAccountIdForCommunityUser() ERROR - caught Exception:' + e);
            System.debug(e.getStackTraceString());
            throw new AuraHandledException('Account id was not found.');
        }          
    }

    // Get account Id
    @AuraEnabled(cacheable=true)
    public static User getUserInfo(){
        Logger logInstance = Logger.getInstance();   
        System.debug(lprefix + 'getUserInfo() ENTRY');

        try{
            User currentUser = [SELECT id, accountId, contactId, Account.OwnerId, Is_Fleet_Community_Manager__c FROM USER WHERE id = :UserInfo.getUserId()];
            System.debug(lprefix + 'getUserInfo() EXIT - Returning user = ' + currentUser);
            return currentUser;
        } catch (Exception e) {
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            System.debug(lprefix + 'getUserInfo() ERROR - caught Exception:' + e);
            System.debug(e.getStackTraceString());
            throw new AuraHandledException('User was not found.');
        }        
        
    }

    @AuraEnabled
    public static List<Contact> getDriversByAccount(String accountId) {
        String communityUserAccountId = null;
        Set<String> accountIds = new Set<String>();
        
        if (accountId == null || accountId == '') {
            communityUserAccountId = getAccountIdForCommunityUser();
        } else {
            communityUserAccountId = accountId;
        }
        
        accountIds.add(communityUserAccountId);
        
        List<Account> childAccList = [SELECT Id, Name 
                                      FROM Account 
                                      WHERE ParentId =: communityUserAccountId];
        
        for(Account acc : childAccList)
        {
            accountIds.add(acc.Id);
        }
        
        Id driverRecordTypeId = getDriverRecordTypeId();
        
        List<Contact> driverList = [SELECT Id, Name, AccountId, Account.Name, 
                                    Title, Email, Phone, MobilePhone, Driver_License_State__c, 
                                    Driver_license_Number__c, ECC_Customer_Reference_Number__c,
                                    CreatedBy.Name, LastModifiedDate
                                    FROM Contact
                                    WHERE AccountId in : accountIds
                                    AND RecordTypeId =: driverRecordTypeId];

        if (driverList != null) System.debug(lprefix + '    Number Drivers retrieved = ' + driverList.size());
        System.debug(lprefix + 'getDriversByAccount() EXIT driverList: ' + driverList);

        return driverList;
    }

    @AuraEnabled
    public static List<Asset> getVehiclesByAccount(String accountId) {
        String communityUserAccountId = null;
        Set<String> accountIds = new Set<String>();
        
        if (accountId == null || accountId == '') {
            communityUserAccountId = getAccountIdForCommunityUser();
        } else {
            communityUserAccountId = accountId;
        }
        
        accountIds.add(communityUserAccountId);
        
        List<Account> childAccList = [SELECT Id, Name 
                                      FROM Account 
                                      WHERE ParentId =: communityUserAccountId];
        
        for(Account acc : childAccList)
        {
            accountIds.add(acc.Id);
        }
        
        Id vehiclesRecordTypeId = getVehicleRecordTypeId();
        
        List<Asset> vehicleList = [SELECT Id, Name, ContactId, AccountId, Contact.Name, Account.Name, Vehicle_Make__c, Vehicle_Model__c, 
                                   Vehicle_Manufacture_Year__c, Vehicle_License_Plate__c, VIN__c, Customer_Vehicle_Number__c, Vehicle_Type__c, Vehicle_Type_Other__c, CreatedBy.Name, LastModifiedDate
                                   FROM Asset
                                   WHERE AccountId in : accountIds
                                   AND RecordTypeId = :vehiclesRecordTypeId];

        if (vehicleList != null) System.debug(lprefix + '    Number Vehicles retrieved = ' + vehicleList.size());
        System.debug(lprefix + 'getVehiclesByAccount() EXIT - vehicleList: ' + vehicleList);
            
        return vehicleList;
    }

    //---Get Users (this is cachable to be used by the wire)
    @AuraEnabled(cacheable=true)
    public static List<User> getMyUsersByAccountCached(String accountId) 
    {
        return loadUsersByAccount(accountId);
    }

    //---Get Users (this not cachable to give fresh data after changes)
    @AuraEnabled
    public static List<User> getMyUsersByAccount(String accountId) 
    {
        return loadUsersByAccount(accountId);
    }

    //---Method to load users by account
    public static List<User> loadUsersByAccount(String accountId)
    {
        String communityUserAccountId = null;
        if (accountId == null || accountId == '') {
            communityUserAccountId = getAccountIdForCommunityUser();
        } else {
            communityUserAccountId = accountId;
        }
 
        List<User> userList = [SELECT Id, Name, FirstName, LastName, Email, Phone, MobilePhone, Username, CommunityNickname,
                    ECC_Is_Primary_Contact__c, Fleet_SPOC_Purchasing__c,Fleet_Secondary_SPOC__c, Fleet_AP_Contact__c, Is_Fleet_Community_Manager__c, Title, Address, IsActive
                    FROM User
                    WHERE AccountId = :communityUserAccountId];

        System.debug(lprefix + 'loadUsersByAccount: ' + userList);
        return userList;
    }

    //---Get the Driver Record Type
    @AuraEnabled(cacheable=true)
    public static String getDriverRecordTypeId(){
        return Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_DRIVER).getRecordTypeId();
    }

    //---Get the B2b Contact Record Type
    @AuraEnabled(cacheable=true)
    public static String getB2bContactRecordTypeId(){
        return Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
    }

    //---Get the Vehicle Record Type
    @AuraEnabled(cacheable=true)
    public static String getVehicleRecordTypeId(){
        return Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(Fleet_Values.ASSET_RECORD_TYPE_VEHICLE).getRecordTypeId();
    }

    /*
     Handle Saving community records. If this class is changed to with sharing
     split out into a without sharing class
    */
    @AuraEnabled
    public static Contact saveCommunityContact(String fields){
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix+ 'saveCommunityContact: ' + fields);
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Contact creation');
        Contact newContact = (Contact) JSON.deserialize(fields, Contact.class);
        //newContact.OwnerId = ownerId;
        // update the ownerId
        try {
            if (newContact.MobilePhone == null) newContact.MobilePhone = '';
            insert newContact;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Contact creation', JSON.serialize(newContact));
            return newContact;
        } catch (exception e) {
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            throw new AuraHandledException('Unable to insert contact: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Asset saveCommunityAsset(String fields){
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix+ 'saveCommunityAsset: ' + fields);
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Asset creation');
        Asset newVehicle = (Asset) JSON.deserialize(fields, Asset.class);
        try {
            insert newVehicle;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Asset creation', JSON.serialize(newVehicle));
            return newVehicle;
        } catch (exception e) {           
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            throw new AuraHandledException('Unable to insert vehicle: ' + e.getMessage());
        }  
    }

    @AuraEnabled
    public static string deleteCommunityAsset(String vehicleId){
        Logger logInstance = Logger.getInstance();
        if (vehicleId == null || vehicleId == '') throw new AuraHandledException('Invalid vehicleId Paramater');
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Asset delete');
        Asset vehicleToDelete = new Asset();
        vehicleToDelete.Id = vehicleId;
        try {
            delete vehicleToDelete;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Asset delete', JSON.serialize(vehicleToDelete));
            return 'Success';
        } catch (exception e) {           
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            throw new AuraHandledException('Unable to delete record with Id: ' + vehicleId);
        }
    }
    
    @AuraEnabled
    public static string addNoteAsset(String vehicleId, String note){
         Logger logInstance = Logger.getInstance();
        if (vehicleId == null || vehicleId == '') throw new AuraHandledException('Invalid vehicleId Paramater');
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Asset update');
        List<Asset> assetList = [select id, Vehicle_Notes__c from Asset where id =: vehicleId];
        
        if(assetList.size() > 0)
        {
            try {
                if(assetList[0].Vehicle_Notes__c == null) assetList[0].Vehicle_Notes__c = '';
                
                assetList[0].Vehicle_Notes__c = note + '\n By ' + [select Name from User where id =: UserInfo.getUserId()].Name + ' - ' + System.now().format('MM/dd/yyyy HH:mm') + '\n\n' + assetList[0].Vehicle_Notes__c;
                
                update assetList;
                logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Asset update', JSON.serialize(assetList));
                return 'Success';
            } catch (exception e) {
                logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
                throw new AuraHandledException('Unable to delete record with Id: ' + vehicleId);
            }
        }
        
        return 'Success';
    }
    
    @AuraEnabled
    public static string addNoteContact(String contactId, String note){
        Logger logInstance = Logger.getInstance();
        if (contactId == null || contactId == '') throw new AuraHandledException('Invalid contactId Paramater');
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Contact update');
        List<Contact> contactList = [select id, Driver_Notes__c from Contact where id =: contactId];
        
        if(contactList.size() > 0)
        {
            try {
                if(contactList[0]. Driver_Notes__c == null) contactList[0]. Driver_Notes__c = '';
                
                contactList[0]. Driver_Notes__c = note + '\n By ' + [select Name from User where id =: UserInfo.getUserId()].Name + ' - ' + System.now().format('MM/dd/yyyy HH:mm') + '\n\n' + contactList[0]. Driver_Notes__c;
                
                update contactList;
                logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Contact update', JSON.serialize(contactList));
                return 'Success';
            } catch (exception e) {
                logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
                throw new AuraHandledException('Unable to delete record with Id: ' + contactId);
            }
        }
        
        return 'Success';
    }

    @AuraEnabled
    public static string deleteCommunityContact(String contactId){
        Logger logInstance = Logger.getInstance();
        if (contactId == null || contactId == '') throw new AuraHandledException('Invalid contactId Paramater');
        logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Contact delete');
        Contact contactToDelete = new Contact();
        contactToDelete.Id = contactId;
        try {
            delete contactToDelete;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Contact delete', JSON.serialize(contactToDelete));
            return 'Success';
        } catch (exception e) {
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            throw new AuraHandledException('Unable to delete record with Id: ' + contactId);
        }
    }

    @AuraEnabled
    public static string resetCommunityUserPassword(String userId) {
        
        return  Fleet_UserUtil.resetPasswordWithEmail(userId);
    }

    @AuraEnabled
    public static string unlockCommunityUser(String userId) {

        return Fleet_UserUtil.unlockUser(userId);

    }

    @AuraEnabled
    public static Boolean checkForLockedUser(String userId) {

        return Fleet_UserUtil.isUserLocked(userId);

    }

    @AuraEnabled
    public static Boolean checkForActiveUser(String userId) {

        return Fleet_UserUtil.isUserActive(userId);

    }
    
    @AuraEnabled
    public static string deactivateCommunityUser(String userId) {
        System.debug('-----------------User ID: ' + userId);
        System.debug(UserInfo.getUserId());
        if(userId == UserInfo.getUserId()){
            return 'invalidUser';
        }

        return Fleet_UserUtil.deactivateUser(userId);

    }

    @AuraEnabled
    public static string createCommunityUser(String communityContactString) {

        System.debug('-----Start convert contact to community User----');
        System.debug(communityContactString);

        try {
            Contact communityContact = (Contact) JSON.deserialize(communityContactString, Contact.class);
        
            // build id set
            Set<id> contactIdSet = new Set<id>();
            contactIdSet.add(communityContact.Id);

            // determine if contact should be super user
            Boolean isCommunityManager = (communityContact.Is_Fleet_Community_Manager__c != null && communityContact.Is_Fleet_Community_Manager__c == true) ? true : false;

            Fleet_CommunityUserBuilder.convertContactToCommunityUser(contactIdSet, isCommunityManager);

            return 'Success';

        } catch (exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            System.debug('There was an error converting the contact to a community user: ' + e.getMessage());
            throw new AuraHandledException('Unable to create a user at this time, please try again later' + e.getMessage());
        }

    }

    //---Call to Save the User Updates
    @AuraEnabled
    public static string updateCommunityUser(String communityUserString){
        Logger logInstance = Logger.getInstance();
        System.debug(lprefix + '-----Start User update----Converting to User sobject...');

        try {
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before User update');
            User communityUser = (User) JSON.deserialize(communityUserString, User.class);
            System.debug(lprefix + 'User to Update: ' + communityUser);
            update communityUser;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After User update', JSON.serialize(communityUser));

            //---Need the Contact Id for the User
            User updateUser = [SELECT Id, ContactId FROM User WHERE Id = :communityUser.Id];
            
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'Before Contact update');
            Contact updateContact = new Contact( Id=updateUser.ContactId);
            updateContact.ECC_Is_Primary_Contact__c = communityUser.ECC_Is_Primary_Contact__c;
            updateContact.Fleet_SPOC_Purchasing__c = communityUser.Fleet_SPOC_Purchasing__c;
            updateContact.Fleet_Secondary_SPOC__c = communityUser.Fleet_Secondary_SPOC__c;// New Field added for story Salesforce-263
            updateContact.Fleet_AP_Contact__c = communityUser.Fleet_AP_Contact__c;
            updateContact.Is_Fleet_Community_Manager__c = communityUser.Is_Fleet_Community_Manager__c;
            System.debug(lprefix + 'Contact to Update: ' + communityUser);
            update updateContact;
            logInstance.log('Community Util', 'Fleet_CommunityUtil', 'After Contact update', JSON.serialize(updateContact));
            return 'success';
        }
        catch(Exception e){
       
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            System.debug('There was an error updating the user info: ' + e.getMessage());
            throw new AuraHandledException('Unable to edit user info at this time: ' + e.getMessage());
        }
    }

     //---Get the Community User Info
     @AuraEnabled(cacheable=true)
     public static CommunityUserInfo getCommunityUserInfo()
     {
        System.debug(lprefix + 'getCommunityUserInfo() ENTRY');
        CommunityUserInfo cInfo = new CommunityUserInfo();

        try 
        {
            User currentUser = [SELECT id, Account.ECC_Account_Number__c, Account.Fleet_Specialist__r.Name, Account.Fleet_Specialist__r.Phone, Account.Fleet_Specialist__r.Email  FROM USER WHERE id = :UserInfo.getUserId()];

            if (currentUser != null)
            {
                cInfo.customerAccount = currentUser.Account.ECC_Account_Number__c;
                cInfo.repName = currentUser.Account.Fleet_Specialist__r.Name;
                cInfo.repPhone = currentUser.Account.Fleet_Specialist__r.Phone;
                cInfo.repEmail = currentUser.Account.Fleet_Specialist__r.Email;
            }

        } catch (Exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Community Util', 'Fleet_CommunityUtil', e);
            System.debug(lprefix + 'getCommunityUserInfo() ERROR - caught Exception:' + e);
            System.debug(e.getStackTraceString());
            throw new AuraHandledException('Community User Info not found.');
        }     

        return cInfo;
     }

     //---Class to return for info
     public without sharing class CommunityUserInfo {
        @AuraEnabled public String customerAccount { get; set; }
        @AuraEnabled public String repName { get; set; }
        @AuraEnabled public String repEmail { get; set; }
        @AuraEnabled public String repPhone { get; set; }
    }
}