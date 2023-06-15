@IsTest
private class X7S_SiteRegistrationTest {
    @IsTest
    static void testGenerateUser() {

        Account tesPersonAccount = new Account();
        tesPersonAccount.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = TRUE].Id;
        tesPersonAccount.FirstName = 'Test';
        tesPersonAccount.LastName = 'Account';
        tesPersonAccount.OwnerId = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRoleId != NULL LIMIT 1].Id;
        insert tesPersonAccount;

        X7S_SiteRegistration siteRegistration = new X7S_SiteRegistration();

        siteRegistration.firstName = 'TestCommunity';
        siteRegistration.lastName = 'User';
        siteRegistration.email = 'test+DiscountTireTestCommunityUser@example.com';
        siteRegistration.phoneType = X7S_SiteRegistrationController.getPhoneTypes().get('Mobile');
        siteRegistration.phoneNumber = '+17732025862';
        siteRegistration.streetAddress = '200 N Jefferson St';
        siteRegistration.country = X7S_SiteRegistrationController.getCountries().get('United States of America');
        siteRegistration.postalCode = '53202';
        siteRegistration.city = 'Milwaukee';
        siteRegistration.state = X7S_SiteRegistrationController.getStates().get('Wisconsin');
        siteRegistration.domain = 'discounttire.com';
        siteRegistration.password = 'ValidPassword1';

        User result = siteRegistration.generateNewUser();

        result.ProfileId = Label.Customer_Community_User_Default_Profile_Id;
        result.ContactId = [SELECT Id, PersonContactId FROM Account WHERE Id =:tesPersonAccount.Id].PersonContactId;


        System.assertEquals(siteRegistration.firstName, result.FirstName);
        System.assertEquals(siteRegistration.lastName, result.LastName);
        System.assertEquals(siteRegistration.email, result.Username);
        System.assertEquals(siteRegistration.email, result.Email);
        System.assertEquals(siteRegistration.phoneNumber, result.MobilePhone);
        System.assertEquals(siteRegistration.streetAddress, result.Street);
        System.assertEquals(siteRegistration.country, result.Country);
        System.assertEquals(siteRegistration.postalCode, result.PostalCode);
        System.assertEquals(siteRegistration.city, result.City);
        System.assertEquals(siteRegistration.state, result.State);

        insert result;

        System.assertNotEquals(null, result.Id);

        Test.startTest();
        X7S_SiteRegistration.updateAccountFields(result.Id);
        Test.stopTest();
    }
}