@isTest
public with sharing class TestResourceAbsenceController_Test {
    @isTest
    static void testGetUserAccountTimezone() {
        // Create a test user with a known timezone
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User']; // Change the profile name as needed
        User testUser = new User(
            Alias = 'testUser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/New_York', // Set the expected timezone here
            UserName = 'testuser@test.com.coedev'
        );
        insert testUser;

        // Set the test context to the created user
        System.runAs(testUser) {
            // Call the AuraEnabled method to get the user's account timezone
            String userTimezone = TestResourceAbsenceController.getUserAccountTimezone();

            // Verify that the user's timezone is as expected
            System.assertEquals('America/New_York', userTimezone);
        }
    }
}