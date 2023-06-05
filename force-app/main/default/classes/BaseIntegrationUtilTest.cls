@isTest
public class BaseIntegrationUtilTest {
    
    
    @IsTest 
    public static void testIntegrationUtil() 
    {
        //---This tests calling out for data

        Int_Message__c intMsg = new Int_Message__c();

        Test.startTest();
        BaseIntegrationUtil.recordSuccess(intMsg);
        BaseIntegrationUtil.recordError(intMsg, 'xxx');

        BaseIntegrationUtil.recordNoToken(intMsg, 'x');
        BaseIntegrationUtil.handleExternalError(intMsg, 'x');

        String body = 'x';
        BaseIntegrationUtil.recordGetResults(intMsg, body);

        body = '';
        BaseIntegrationUtil.recordGetResults(intMsg, body);


        Integer testVal1 = BaseIntegrationUtil.getSettingIntValue('No Value', 'APPT');
        Integer testVal2 = BaseIntegrationUtil.getSettingIntValue('dtSourceSystem', 'APPT');  //---This is not an integer value
        Boolean testVal3 = BaseIntegrationUtil.getSettingBooleanValue('No Value', 'APPT');
        Boolean testVal4 = BaseIntegrationUtil.getSettingBooleanValue('dtSourceSystem', 'APPT');  //---This is not an integer value

        String bToken1 = BaseIntegrationUtil.parseBToken(intMsg, '{"access_token": "00D3"}');
        String bToken2 = BaseIntegrationUtil.parseBToken(intMsg, '{"error": "No token"}');

        Test.stopTest();
    }
}