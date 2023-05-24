/**
 * Created by kentheberling on 5/7/18.
 */

public with sharing class Peak_JSONFeedController {
  public static final String FEED_TYPE_TEST = 'Test';
  private static Logger logInstance = Logger.getInstance();

  /*
        Generic wrapper for http response
     */
  public class ResponseWrapper {
    @AuraEnabled
    public Integer responseCode { get; set; }

    @AuraEnabled
    public String responseStatus { get; set; }

    @AuraEnabled
    public String errorMessage { get; set; }

    @AuraEnabled
    public String responseBody { get; set; }
  }

  /*
        Get the JSON Feed, unwrap it, and return it
     */
  @AuraEnabled
  public static ResponseWrapper getJSONFeed(
    String endpointUrl,
    String recordsToShow,
    String feedType
  ) {
    ResponseWrapper responseWrapper = new ResponseWrapper();

    // If we're in test mode, just get a Peak_Content Object
    if (feedType == FEED_TYPE_TEST) {
      responseWrapper.responseCode = 200;

      // Temp content object!
      Peak_ContentObject testContentObject = new Peak_ContentObject();
      testContentObject.title = 'Title of Content';
      testContentObject.dateTimeField = Datetime.newInstance(
        System.today(),
        Time.newInstance(3, 3, 3, 0)
      );
      testContentObject.description = 'Milwaukee, WI';
      testContentObject.fullDescription = '7Summits Headquarters';
      testContentObject.url = 'http://7summitsinc.com';

      // Serialize it!
      responseWrapper.responseBody = JSON.serialize(testContentObject);
    } else {
      // When not in test mode, get the actual response
      // Set it up

      Http http = new Http();
      HttpRequest request = new HttpRequest();
      request.setEndpoint(endpointUrl);
      request.setMethod('GET');

      try {
        // Get that request
        HttpResponse response = http.send(request);

        // Process it
        responseWrapper.responseCode = response.getStatusCode();
        responseWrapper.responseStatus = response.getStatus();
        responseWrapper.responseBody = response.getBody();
      } catch (Exception e) {
        logInstance.log('Customer Care', 'Peak_JSONFeedController', e);
        responseWrapper.errorMessage = e.getMessage();
      }
    }

    return responseWrapper;
  }
}