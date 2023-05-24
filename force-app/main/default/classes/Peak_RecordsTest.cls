/**
 * Created by kentheberling on 8/23/18.
 */

@isTest
public class Peak_RecordsTest {

    /*
        Some test data to use
     */
    // Object
    private static final String objectType = 'Contact';

    // Fields
    private static final  List<String> testFields = new List<String>{
            'Id','Email'
    };

    /*
        Test setup
     */
    @testSetup
    static void testSetup() {
        //Contact testContact = Peak_TestUtils.createTestContact();
        User testUser = Peak_TestUtils.createStandardUser();//Peak_TestUtils.createStandardUserNoContact();
        insert testUser;
    }

    /*
        Test just the helpers
     */
    @isTest
    public static void testQueryHelpers() {

        // Get test user ID for queries
        List<Contact> testContacts = [Select Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];
        Id testId = testContacts[0].Id;

        List<User> testUsers = [Select Id from User where Email = :Peak_TestConstants.STANDARD_EMAIL];
        User testUser = testUsers[0];

        // ID where clause
        String idWhereClause = Peak_RecordQueryHelper.buildIdWhereClause(String.valueOf(testId));

            // Build query string and validate it's correct!
            String queryString = Peak_RecordQueryHelper.buildQueryString(objectType, testFields, idWhereClause);
            System.assertEquals(queryString, 'Select Id, Email from Contact where Id = \'' + testId + '\'');

            // Now query
            List<SObject> testResults = Peak_RecordQueryHelper.executeQuery(queryString);
            system.assertEquals(testResults.size(), 1); // assert the one record is found

            // And NOW, test
            List<Peak_ContentObject> pcoList = Peak_RecordQueryHelper.formatRecordDetailWithLabels(objectType, testResults[0], testFields);
            system.assertEquals(pcoList.size(), 2); // assert that the two fields are found / formatted
    }

    /*
        Test the detail and
     */
    @isTest
    public static void testControllers() {

        // Get test user ID for queries
        List<Contact> testContacts = [Select Id from Contact where Email = :Peak_TestConstants.STANDARD_EMAIL];
        Id testId = testContacts[0].Id;

        List<User> testUsers = [Select Id from User where Email = :Peak_TestConstants.STANDARD_EMAIL];
        User testUser = testUsers[0];

        Peak_Response testResponse = new Peak_Response();

        /*
            Detail Controller Tests
         */

        String testFieldsString = Peak_Utils.buildStringFromList(testFields);
        testFieldsString = testFieldsString.replaceAll(' ','');

        // Get a successful detail
        testResponse = Peak_RecordDetailController.getRecordDetail(String.valueOf(testId),objectType,testFieldsString);
        system.assertEquals(testResponse.success,true); // it worked!
        system.assertEquals(testResponse.results.size(),1); // found one record!

        // Fail with bad object
        testResponse = Peak_RecordDetailController.getRecordDetail(String.valueOf(testId),'Not a Real Object',testFieldsString);
        system.assertEquals(testResponse.success,false); // did not work

        // with bad fields
        testResponse = Peak_RecordDetailController.getRecordDetail(String.valueOf(testId),objectType,'Bad Apple');
        system.assertEquals(testResponse.success,false); // did not work

        // with no match id
        testResponse = Peak_RecordDetailController.getRecordDetail(Peak_TestUtils.getFakeId(Contact.SObjectType),objectType,testFieldsString);
        system.assertEquals(testResponse.success,true); // not actually a failure
        system.assertEquals(testResponse.results.size(),0); // but no results


    }

}