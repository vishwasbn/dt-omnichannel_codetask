@IsTest
private class X7S_SiteRegistrationControllerTest {
    @IsTest
    static void testValidateUsername() {
        User existingUser = [SELECT Id, Username FROM User LIMIT 1];

        String duplicateUsername = existingUser.Username;
        String uniqueUsername = 'definitely_a_brand_new_username@example.com';

        Boolean isDuplicateUsernameValid = X7S_SiteRegistrationController.validateUsername(duplicateUsername);
        Boolean isUniqueUsernameValid = X7S_SiteRegistrationController.validateUsername(uniqueUsername);

        System.assertEquals(false, isDuplicateUsernameValid);
        System.assertEquals(true, isUniqueUsernameValid);
    }

    @IsTest
    static void testValidatePassword() {
        String shortPassword = 'short1';
        String passwordWithoutLetters = '123456789';
        String passwordWithoutNumbers = 'asdfghjkl';
        String validPassword = 'validpassword12';

        System.assertEquals(false, X7S_SiteRegistrationController.validatePassword(shortPassword));
        System.assertEquals(false, X7S_SiteRegistrationController.validatePassword(passwordWithoutLetters));
        System.assertEquals(false, X7S_SiteRegistrationController.validatePassword(passwordWithoutNumbers));
        System.assertEquals(true,  X7S_SiteRegistrationController.validatePassword(validPassword));
    }

    @IsTest
    static void testGetStates() {
        Map<String, String> states = X7S_SiteRegistrationController.getStates();

        System.assertEquals(51, states.size(), '50 States + DC');
    }

    @IsTest
    static void testGetProvinces() {
        Map<String, String> states = X7S_SiteRegistrationController.getProvinces();

        System.assertEquals(13, states.size());
    }

    @IsTest
    static void testGetCountries() {
        Map<String, String> states = X7S_SiteRegistrationController.getCountries();

        System.assertEquals(2, states.size(), 'US + Canada');
    }

    @IsTest
    static void testGetPhoneTypes() {
        Map<String, String> states = X7S_SiteRegistrationController.getPhoneTypes();

        System.assertEquals(3, states.size());
    }
}