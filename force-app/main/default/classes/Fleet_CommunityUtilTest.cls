@isTest
public with sharing class Fleet_CommunityUtilTest {
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

        Fleet_CommunityUtil.addNoteAsset(vehicle.Id, 'test');

        Contact b2bContact = new Contact();
        b2bContact.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        b2bContact.FirstName = 'Test';
        b2bContact.LastName = 'b2b Contact';
        insert b2bContact;
        
        Fleet_CommunityUtil.addNoteContact(b2bContact.Id, 'test');
    }

    @isTest
    public static void testgetAccountIdForCommunityUser() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){

            User newUser = [SELECT id, accountId, ContactId FROM USER WHERE id = :UserInfo.getUserId()];                  
            System.debug('----------Start Test----------');
            Test.startTest();

            String accountId = Fleet_CommunityUtil.getAccountIdForCommunityUser();

            Test.stopTest();
            System.assert(newUser.accountId == accountId, 'Account Id Matched');
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testgetCommunityUserInfo() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        myAccount.ECC_Account_Number__c = '123';
        update myAccount;

        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){

            User currentUser = [SELECT id, Account.ECC_Account_Number__c, Account.Fleet_Specialist__r.Name, Account.Fleet_Specialist__r.Phone, Account.Fleet_Specialist__r.Email  FROM USER WHERE id = :UserInfo.getUserId()];                  
            System.debug('----------Start Test----------');
            Test.startTest();

            Fleet_CommunityUtil.CommunityUserInfo cInfo = Fleet_CommunityUtil.getCommunityUserInfo();

            Test.stopTest();
            System.assert(currentUser.Account.ECC_Account_Number__c == cInfo.customerAccount, 'Account number matched');
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testgetUserInfo() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            User u = Fleet_CommunityUtil.getUserInfo();

            Test.stopTest();
            System.assert(u.Id == testUser.Id, 'User Id Matched');
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testcreateCommunityUser() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        
        Contact newCommunityUser = new Contact();
        newCommunityUser.FirstName = 'Test';
        newCommunityUser.LastName = 'Community Contact';
        newCommunityUser.Email = 'test@email123.orgtest';
        newCommunityUser.Is_Fleet_Community_Manager__c = false;
        newCommunityUser.AccountId = myAccount.Id;
        newCommunityUser.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        //{"FirstName":"Test","LastName":"Community Contact","Email":"test@email123.orgtest","Is_Fleet_Community_Manager__c":true,"RecordTypeId":"0123F00000218l4QAA"}
        String contactString = JSON.serialize(newCommunityUser);

        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
            System.debug('----------Start Test----------');
            Test.startTest();

            Contact createdContact = Fleet_CommunityUtil.saveCommunityContact(contactString);
            String response = Fleet_CommunityUtil.createCommunityUser(JSON.serialize(createdContact));


            Test.stopTest();

            User communityUserResult = [select Id from User where LastName = 'Community Contact' limit 1];
            Contact communityContact = [select Id, LastName from Contact where LastName = 'Community Contact' limit 1 ];

            System.assertEquals('Success', response);
            System.assert(communityUserResult != null, 'New User Created');
            System.assert('Community Contact' == communityContact.LastName, 'Community Contact Creted');
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testcreateCommunityManager() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        
        Contact newCommunityUser = new Contact();
        newCommunityUser.FirstName = 'Test';
        newCommunityUser.LastName = 'Community Contact';
        newCommunityUser.Email = 'test@email123.orgtest';
        newCommunityUser.Is_Fleet_Community_Manager__c = true;
        newCommunityUser.AccountId = myAccount.Id;
        newCommunityUser.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        //{"FirstName":"Test","LastName":"Community Contact","Email":"test@email123.orgtest","Is_Fleet_Community_Manager__c":true,"RecordTypeId":"0123F00000218l4QAA"}
        String contactString = JSON.serialize(newCommunityUser);

        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
            System.debug('----------Start Test----------');
            Test.startTest();

            Contact createdContact = Fleet_CommunityUtil.saveCommunityContact(contactString);
            String response = Fleet_CommunityUtil.createCommunityUser(JSON.serialize(createdContact));


            Test.stopTest();

            User communityUserResult = [select Id from User where LastName = 'Community Contact' limit 1];
            Contact communityContact = [select Id, LastName from Contact where LastName = 'Community Contact' limit 1 ];

            System.assertEquals('Success', response);
            System.assert(communityUserResult != null, 'New User Created');
            System.assert('Community Contact' == communityContact.LastName, 'Community Contact Creted');
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testupdateCommunityUser() {
        /*List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];

        List<User> communityUser = [SELECT id, Title FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        testUser.Title = 'Test Title';
        
        // Run Test As user
        System.runAs(testUser){
            System.debug('----------Start Test----------');
            Test.startTest();

            String response = Fleet_CommunityUtil.updateCommunityUser(JSON.serialize(testUser));

            Test.stopTest();

            User updatedUser = [select Id, Title from User WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id limit 1];

            System.assertEquals('success', response);
            System.assertEquals('Test Title', testUser.Title, 'User Updated');
            System.debug('----------End Test----------');
        }*/
    }

    @isTest
    public static void testgetDriversByAccount() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            List<Contact> drivers = Fleet_CommunityUtil.getDriversByAccount(myAccount.Id);

            Test.stopTest();
            System.assert(drivers.size() > 0, 'Driver found for my account');
            System.assertEquals('Test Driver', drivers[0].Name);
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testgetVehiclesByAccount() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            List<Asset> vehicles = Fleet_CommunityUtil.getVehiclesByAccount(myAccount.Id);

            Test.stopTest();
            System.assert(vehicles.size() > 0, 'Driver found for my account');
            System.assertEquals('2006', vehicles[0].Vehicle_Manufacture_Year__c);
            System.debug('----------End Test----------');
        }
    }

    @isTest
    public static void testgetMyUsersByAccount() {

        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            List<User> users = Fleet_CommunityUtil.getMyUsersByAccount(myAccount.Id);
            System.debug(users);

            System.assert(users.size() > 0, 'Users Found for acccount');
            System.assertEquals('Test Contact', users[0].Name);
            System.debug('----------End Test----------');
        }
        
    }

    @isTest
    public static void testsaveCommunityAsset() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];

        Asset vehicle = new Asset();
        vehicle.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(Fleet_Values.ASSET_RECORD_TYPE_VEHICLE).getRecordTypeId();
        vehicle.Name = '2010 Toyota Prius';
        vehicle.AccountId = myAccount.Id;
        vehicle.Vehicle_Make__c = 'Toyota';
        vehicle.Vehicle_Model__c = 'Prius';
        vehicle.Vehicle_Manufacture_Year__c = '2010';
        vehicle.Vehicle_License_Plate__c = 'ABC123';
        vehicle.VIN__c = 'zyxwvut654321';
        vehicle.Customer_Vehicle_Number__c = '001122334455';

        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            Asset vehicleReturn = Fleet_CommunityUtil.saveCommunityAsset(JSON.serialize(vehicle));

            Test.stopTest();
            System.assertEquals('2010 Toyota Prius', vehicleReturn.Name);
            System.debug('----------End Test----------');
        }
    }
    @isTest
    public static void testsaveCommunityContact() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        Contact driver = new Contact();
        driver.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_DRIVER).getRecordTypeId();
        driver.FirstName = 'Test';
        driver.LastName = 'Community Driver';
        driver.AccountId = myAccount.Id;

        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            Contact returnedDriver = Fleet_CommunityUtil.saveCommunityContact(JSON.serialize(driver));

            Test.stopTest();

            Contact savedDriver = [select LastName from Contact where LastName = 'Community Driver' limit 1];
            System.assertEquals('Community Driver', savedDriver.LastName);
            System.assert(returnedDriver != null, 'Saved Contact was returned successfully');
            System.debug('----------End Test----------');
        }
    }
    @isTest
    public static void testdeleteCommunityAsset() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];

        Asset vehicle = [select Id from Asset where VIN__c = 'zyxwvut654321'];

        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            String result = Fleet_CommunityUtil.deleteCommunityAsset(vehicle.Id);

            Test.stopTest();
            List<Asset> vehicleList = [select Id from Asset where Name = '2006 Toyota Prius'];
            System.assertEquals('Success', result);
            System.assert(vehicleList.size() < 1, 'Vehicle was deleted');
            System.debug('----------End Test----------');

        }
    }


    @isTest
    public static void testgetB2bContactRecordTypeId() {

        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            String recordTypeId = Fleet_CommunityUtil.getB2bContactRecordTypeId();
            System.debug(recordTypeId);
            
            System.assert(recordTypeId != null, 'Record Type Id Found');
            System.debug('----------End Test----------');
        }
        
    }

     @isTest
     public static void testdeleteCommunityContact() {
         List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
         List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
         User testUser = communityUser[0];

         Contact driver = [select Id, ECC_Contact_Person_Id__c from Contact where Name = 'Test Driver'];
         driver.ECC_Contact_Person_Id__c = '123';
         update driver;

         // Run Test As user
         System.runAs(testUser){
                 
             System.debug('----------Start Test----------');
             Test.startTest();

             String result = Fleet_CommunityUtil.deleteCommunityContact(driver.Id);

             Test.stopTest();
             List<Contact> driverNotFound = [select Id from Contact where Name = 'Test Driver'];

             System.assertEquals('Success', result);
             System.assert(driverNotFound.size() < 1, 'Contact was deleted');
             System.debug('----------End Test----------');

         }
     }

     @isTest
     public static void testUnlockCommunityUser() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];         
                 
        System.debug('----------Start Test----------');
        Test.startTest();
        String result = Fleet_CommunityUtil.unlockCommunityUser(testUser.Id);
        Test.stopTest();

        System.assertEquals('success', result);
        System.debug('----------End Test----------');
         
     }

     @isTest
     public static void testCheckForLockedUser() {
         List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
         List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
         User testUser = communityUser[0];

         // Run Test As user
         System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            Boolean result = Fleet_CommunityUtil.checkForLockedUser(testUser.Id);

            Test.stopTest();
            System.debug(result); 

            System.assertEquals(false, result);
            System.debug('----------End Test----------');

         }
     }

     @isTest
     public static void testCheckForActiveUser() {
         List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
         List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
         User testUser = communityUser[0];

         // Run Test As user
         System.runAs(testUser){
                 
            System.debug('----------Start Test----------');
            Test.startTest();

            Boolean result = Fleet_CommunityUtil.checkForActiveUser(testUser.Id);

            Test.stopTest();
            System.debug(result); 

            System.assertEquals(true, result);
            System.debug('----------End Test----------');

         }
     }

     @isTest
     public static void testDeactivateCommunityUser() {      

        // Find user to run as
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
                         
        System.debug('----------Start Test----------');
        Test.startTest();
        String result = Fleet_CommunityUtil.deactivateCommunityUser(testUser.Id);
        Test.stopTest();

        System.assertEquals('success', result);
        System.debug('----------End Test----------');

         
     }

     
     @isTest
     public static void testResetCommunityUserPassword() {
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        System.runAs(testUser){

            System.debug('----------Start Test----------');
            Test.startTest();

            // Negative Test
            String result = Fleet_CommunityUtil.resetCommunityUserPassword('0053F000007U27zQAC');

            System.debug(result);
        
            Test.stopTest();

            System.assertEquals('error', result);
            System.debug('----------End Test----------');

        }

        

     }  

}