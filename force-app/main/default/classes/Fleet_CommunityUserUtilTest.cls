@isTest
public with sharing class Fleet_CommunityUserUtilTest {
    @TestSetup
    static void makeData(){
        Account newAccount = new Account(Name = 'Test Account12345678910');
        insert newAccount;    

        TestCommunityUserFactory.createCommunityUserAsAdmin(newAccount.id, 'Fleet Customer Community User','fleetDev2.com');
        

    }

    @isTest
    public static void setProfileTest(){

        // Find account created from the setup
        List<Account> myAccountList = [SELECT id FROM Account WHERE Name = 'Test Account12345678910'];
        Account myAccount = myAccountList[0];
        // Get the user created as part of the setup
        List<User> communityUser = [SELECT id, profileId, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUser = communityUser[0];

        List<Profile> commmunityProfile = [SELECT id, Name FROM Profile WHERE Name = 'Fleet Customer Community User' Limit 1];                

        Id communityProfileId = commmunityProfile[0].Id;

        System.debug(communityProfileId);

        List<id> communityUserIds = new List<Id>();
        communityUserIds.add(testUser.id);
       


        Test.startTest();

        Fleet_CommunityUserUtil.setProfile(communityUserIds, communityProfileId);

        Test.stopTest();
        
        List<User> communityUserResult = [SELECT id, profileId, accountId, Profile.Name, isActive FROM USER WHERE Profile.Name = 'Fleet Customer Community User' AND accountId = :myAccount.id];      
        User testUserResult = communityUser[0];
        System.assert(testUser.profileId == communityProfileId, 'profile assigned');
        
        

        
    }


}