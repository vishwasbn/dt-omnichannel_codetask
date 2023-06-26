/**
 * Created by kentheberling on 4/24/18.
 */
@isTest
public with sharing class Peak_RSSTest {
    private class mockCallout implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            String body = '<?xml version="1.0" encoding="UTF-8" ?> <rss version="2.0"> <channel> <title>Title</title> <link>http://www.google.com</link> <description>Description</description> <item> <title>Title</title> <link>http://www.google.com/xml/xml_rss.asp</link> <author>Test Author</author> <category> Dublin, Ireland </category> <pubdate> 8/5/2017 </pubdate> <description>Description</description> <guid>1234</guid> </item> </channel> </rss>';
            res.setBody(body);
            return res;
        }
    }

    static testMethod void testGetRSSFeedList() {
        Test.setMock(HttpCalloutMock.class, new mockCallout());
        Test.startTest();
        List<Peak_RSS.RSSWrapper> wrapper =  Peak_RSS.getRSSFeedList('TestURL','10');
        System.assertNotEquals(null, wrapper);
        Test.stopTest();
    }
}