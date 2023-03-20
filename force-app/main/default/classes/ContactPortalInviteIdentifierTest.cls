@isTest
public with sharing class ContactPortalInviteIdentifierTest {
    @TestSetup
    static void makeData(){
        Account newAccount = new Account(Name = 'Test Account12345678910');
        insert newAccount;    

        System.debug('Test Account ID---------' + newAccount.id);
        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');
        
        Contact driver = new Contact();
        driver.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_DRIVER).getRecordTypeId();
        driver.FirstName = 'Test';
        driver.LastName = 'Driver';
        driver.AccountId = newAccount.Id;
        insert driver;

        Asset vehicle = new Asset();
        vehicle.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(Fleet_Values.ASSET_RECORD_TYPE_VEHICLE).getRecordTypeId();
        vehicle.Name = '2006 Toyota Prius';
        vehicle.ContactId = driver.Id;
        vehicle.AccountId = newAccount.Id;
        vehicle.Vehicle_Make__c = 'Toyota';
        vehicle.Vehicle_Model__c = 'Prius';
        vehicle.Vehicle_Manufacture_Year__c = '2006';
        vehicle.Vehicle_License_Plate__c = 'ABC123';
        vehicle.VIN__c = 'zyxwvut654321';
        vehicle.Customer_Vehicle_Number__c = '001122334455';
        insert vehicle;

        Contact b2bContact = new Contact();
        b2bContact.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        b2bContact.FirstName = 'Test';
        b2bContact.LastName = 'b2b Contact';
        insert b2bContact;
    }
    
    @isTest
    public static void testContactPortalInviteIdentifierController() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, ContactId, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        Contact con = [select id from Contact where LastName = 'b2b Contact'];
            
        // Run Test As user
        System.runAs(testUser){
            ContactPortalInviteIdentifierController.checkPortalUser(testUser.ContactId);
            ContactPortalInviteIdentifierController.checkPermissions(testUser.ContactId);
            ContactPortalInviteIdentifierController.checkPermissions(con.Id);
        }
    }
}