@isTest(SeeAllData=true)
public class Peak_LinkedInControllerTest {

    @IsTest
    static void testGetMetaData() {

        List<X7Summits_Social_Component_Settings__mdt> setting = [SELECT LinkedIn_Featured_Posts__c, DeveloperName  FROM X7Summits_Social_Component_Settings__mdt Limit 1];
        
        // Call the method being tested
        Test.startTest();
        String result = Peak_LinkedInController.getMetaData(setting[0].DeveloperName);
        Test.stopTest();
        
        // Verify the expected result
        System.assertEquals(result, setting[0].LinkedIn_Featured_Posts__c);
    }
}