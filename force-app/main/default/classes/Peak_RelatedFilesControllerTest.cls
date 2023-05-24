/**
 * Created by kentheberling on 6/7/18.
 */
@isTest
public class Peak_RelatedFilesControllerTest {


    @testSetup
    static void testSetup() {
        Contact testContact = Peak_TestUtils.createTestContact();
    }

    // Test finding a user
    @isTest
    public static void testGetAttachments(){
        // Set up and run as a standard user
        List<Contact> testContacts = [SELECT Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];
        List<Account> testAccounts = [SELECT Id from Account where Name = :Peak_TestConstants.ACCOUNT_NAME];

        User testUser = Peak_TestUtils.createStandardUserNoContact();
        try {
            testUser.ContactId = testContacts[0].Id;
            insert testUser;
        }catch(Exception e){
            testUser.ContactId = NULL;
            insert testUser;
        }

        Attachment testAttachment = Peak_TestUtils.createAttachment(testAccounts[0].Id);
        insert testAttachment;

        Peak_Response testResponse = Peak_RelatedFilesController.getFilesForCurrentUserForRecord((String)testAccounts[0].Id);

        // Assert that the result is found for this user
        System.assertEquals(testResponse.results.size(),1);


        System.runAs(testUser) {
            // Run the get files method for this user, against Account record
            testResponse = Peak_RelatedFilesController.getFilesForCurrentUserForRecord((String)testAccounts[0].Id);

            // Assert that no result found for test user, as they are not the owner!
            System.assertEquals(testResponse.results.size(),0);
        }

    }
}