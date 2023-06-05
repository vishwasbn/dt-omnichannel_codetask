@isTest
public with sharing class Fleet_CreateActionWithoutSharingTest {
  

    @isTest
    public static void getAccountIdTest(){
        Account newAccount = new Account(Name = 'Test Account12345678910');
        newAccount.Fleet_Public_Notes__c = 'These are some good public notes';
        insert newAccount;    

        System.debug('Test Account ID---------' + newAccount.id);
        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');


        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];
        
        // Run Test As user
        System.runAs(testUser){

            User newUser = [SELECT id, accountId, IsPortalEnabled, ContactId FROM USER WHERE id = :UserInfo.getUserId()];                  

            System.debug('----------Start Test----------');
            Test.startTest();
            //Case returnCase = submitCase(newUser, 'test case description', );
            String accountId = Fleet_ProductPreferencesController.getAccountId();           

            System.assert(newUser.accountId == accountId, 'Account Id Matched');

            Test.stopTest();
            System.debug('----------End Test----------');
        }
        

        
    }
}