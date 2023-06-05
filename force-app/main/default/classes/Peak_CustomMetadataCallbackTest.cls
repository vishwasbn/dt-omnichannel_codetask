/**
 * Created by kentheberling on 7/9/18.
 */
@isTest
public with sharing class Peak_CustomMetadataCallbackTest {


    @isTest
    public static void testPeak_CustomMetadataCallback() {
        Peak_CustomMetadataCallback testCallback = new Peak_CustomMetadataCallback();

        // Test result
        Metadata.DeployResult testResult = new Metadata.DeployResult();
        testResult.success = false;

        testResult.details = new Metadata.DeployDetails();
        testResult.details.componentFailures = new List<Metadata.DeployMessage>();

        // Test context
        Metadata.DeployCallbackContext testContext = new Metadata.DeployCallbackContext();

        // First, test failure
        testCallback.handleResult(testResult,testContext);


        // Now, test success
        testResult.success = true;
        System.assertNotEquals(null, testResult);
        testCallback.handleResult(testResult,testContext);
    }

}