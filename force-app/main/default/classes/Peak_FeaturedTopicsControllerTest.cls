/**
 * Created by jonbalza on 12/18/18.
 */

@IsTest
private class Peak_FeaturedTopicsControllerTest {
    // Testing ConnectApi is difficult and without the "setTest" version of the method, we must use SeeAllData for testing.
    // See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_TestingApex.htm for more details.
    @IsTest(SeeAllData=true)
    static void testGetFeaturedTopics() {
        ConnectApi.ManagedTopicCollection testTopicCollection = new ConnectApi.ManagedTopicCollection();

        Test.startTest();

        testTopicCollection = Peak_FeaturedTopicsController.getFeaturedTopics();
        system.assert(testTopicCollection.managedTopics != null);

        Test.stopTest();
    }
}