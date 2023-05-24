@isTest
public with sharing class Fleet_ProductPreferencesControllerTest {
    @TestSetup
    static void makeData(){
        Account newAccount = new Account(Name = 'Test Account12345678910');
        newAccount.Fleet_Public_Notes__c = 'These are some good public notes';
        insert newAccount;    

        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');
    }

    @isTest
    public static void getAccountIdTest(){
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){

            User newUser = [SELECT id, accountId, ContactId FROM USER WHERE id = :UserInfo.getUserId()];                  

            Test.startTest();

            String accountId = Fleet_ProductPreferencesController.getAccountId();           

            System.assert(newUser.accountId == accountId, 'Account Id Matched');

            Test.stopTest();
        }    
    }

    @isTest
    public static void handleGetInvoicePreferencesTest(){
        
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        System.runAs(testUser){
            Test.startTest();

            String publicNotes = Fleet_ProductPreferencesController.handleGetPublicNotes();       
            
            System.debug(publicNotes);

            Test.stopTest();
        }
    }

    @isTest
    public static void handleProductPreferencesChangeRequestTest(){   
        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        System.runAs(testUser){

            Test.startTest();

            String result = Fleet_ProductPreferencesController.handleProductPreferencesChangeRequest('Test Description', 'Test Subject');       
            
            System.debug(result);

            System.assert(result == 'success', 'Handle Product Preference Change Request');
            
            Test.stopTest();
        }               
    }

}