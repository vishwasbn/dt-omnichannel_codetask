/**
 * Created by kentheberling on 5/9/18.
 */
@isTest
public with sharing class Peak_JSONFeedControllerTest {
    /*
       Mock callout
    */
    private class mockCallout implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            String body = 'test body';
            res.setBody(body);
            return res;
        }
    }


    static testMethod void testGetJSONFeed() {
        // Set mock
        Test.setMock(HttpCalloutMock.class, new mockCallout());

        Test.startTest();

        // Get it!
        Peak_JSONFeedController.ResponseWrapper testResponseWrapper = Peak_JSONFeedController.getJSONFeed('endpoint does not matter, mock will be used','10','feed type does not matter, default will be used');

        // Assert that the two test feed items are found!
        System.assertEquals(testResponseWrapper.responseCode,200);

        // Test debug/test mode
        testResponseWrapper = Peak_JSONFeedController.getJSONFeed('endpoint does not matter, mock will be used','10',Peak_JSONFeedController.FEED_TYPE_TEST);
        System.assertEquals(testResponseWrapper.responseCode,200);

        Test.stopTest();
    }
}