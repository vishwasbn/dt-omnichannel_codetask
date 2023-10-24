/**
 * @description       : 
 * @author            : Lim Gabba
 * @group             : 
 * @last modified on  : 12-12-2022
 * @last modified by  : Lim Gabba
 * Modification Log:
------------------------------------------------------------------------------------
Developer           Mod Number  Date           User Story      Description
------------------------------------------------------------------------------------
Hrushikesh         M-001        22-12-2022                     Static Analysis chnages
Srajan             M-002        03-01-2022                     Updated to follow best practices
Akilan             M-003        17-01-2023                     Added Not Live Method to Increase Coverage
**/
@isTest(SeeAllData=false)
public class WOM_UpdateWaitlistAPITest {
    
    /**
    * @description : It is used to create data needed for testing
    * @author Lim Gabba | 12-12-2022
    * @last modified by  : Srajan
    * @last modified on  : 01-03-2023 
    **/
    @testSetup 
    static void setup() {
        
        List<WOM_Waitlist__c> listWaitlist = WOM_TestDataUtility.createWaitlist(2,false,0);
        listWaitlist[0].WOM_Store_Code__c='123123';
        listWaitlist[0].WOM_Customer_Mobile__c='8097651011';
        listWaitlist[0].WOM_Status__c='cancelled';
        listWaitlist[1].WOM_Status__c='cancelled';
        listWaitlist[1].WOM_Store_Code__c='123123';
        listWaitlist[1].WOM_Customer_Mobile__c='809765';
        insert listWaitlist;
        List<User> usr = WOM_TestDataUtility.createUsers(1,'Test','User','System Administrator',true);
        insert usr;    
    }
    
    /**
    * @description : It is used to test positive functionality of the response from horizon
    * @author Lim Gabba | 12-12-2022 
    * @last modified by  : Srajan
    * @last modified on  : 01-03-2023
    **/
    
    static testmethod void testUpdateWaitlistPositive() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
          test.startTest();
            WOM_UpdateWaitlistWrapper.RequestWrapper requestWrapper = buildUpdateWaitlistRequest();
            WOM_API_Endpoint__mdt addWaitlistEndpointInfo = WOM_APIHelper.getEndPointDetails('WOM_UpdateWaitlist');
            WOM_UpdateWaitlistAPIHttpCalloutMock mockCLass = new WOM_UpdateWaitlistAPIHttpCalloutMock(201, 'OK', 'successes');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            WOM_UpdateWaitlistAPI.updateWaitlistAPICall(requestWrapper); 
            System.assertEquals(true,requestWrapper!=null, 'Update waitlist Positive test case failed');
          test.stopTest();
        }
    }
    
    /**
    * @description : It is used to test negative functionality of the response from horizon
    * @author Lim Gabba | 12-12-2022 
    * @last modified by  : Srajan
    * @last modified on  : 01-03-2023
    **/
     
    static testmethod void testUpdateWaitlistNegative() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
          WOM_UpdateWaitlistWrapper.RequestWrapper requestWrapper = new  WOM_UpdateWaitlistWrapper.RequestWrapper();
          WOM_API_Endpoint__mdt addWaitlistEndpointInfo = WOM_APIHelper.getEndPointDetails('WOM_UpdateWaitlist');
          test.startTest();
            WOM_AddWaitlistAPIHttpCalloutMock mockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            WOM_UpdateWaitlistAPI.updateWaitlistAPICall(requestWrapper); 
            System.assertEquals(true,requestWrapper!=null, 'Update waitlist Negative test case failed');
            
            WOM_API_Endpoint__mdt endpointInfo = WOM_APIHelper.getEndPointDetails('');
            WOM_AddWaitlistAPIHttpCalloutMock mockCLasstest = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, mockCLasstest);
            WOM_UpdateWaitlistAPI.updateWaitlistAPICall(requestWrapper); 
            System.assertEquals(true,requestWrapper!=null, 'Update waitlist Negative test case failed');
            
          test.stopTest();
        }
    }
    
    
    /**
    * @description : test method to cover if the URL is live
    * @author Anuradha | 01-03-2023
    * 
    **/
    static testmethod void testUpdateWaitlistMeta() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WOM_UpdateWaitlistWrapper.RequestWrapper requestWrapper = new  WOM_UpdateWaitlistWrapper.RequestWrapper();
            WOM_API_Endpoint__mdt addWaitlistEndpointInfo = WOM_APIHelper.getEndPointDetails('WOM_UpdateWaitlist');
            addWaitlistEndpointInfo.WOM_isnotlive__c = false;
            test.startTest();
               WOM_AddWaitlistAPIHttpCalloutMock mockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
               Test.setMock(HttpCalloutMock.class, mockCLass);
               WOM_UpdateWaitlistAPI.updateWaitlistAPICall(requestWrapper); 
               System.assertEquals(true,requestWrapper!=null, 'Update waitlist Negative test case failed');
            test.stopTest();
        }
    }
    
     /**
    * @description : It is used to test Not Live functionality 
    * @author Akilan | 17-01-2022 
    **/ 
    static testmethod void testUpdateWaitlistNotLive() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
          WOM_Waitlist__c waitlistRecord = [SELECT Id FROM WOM_Waitlist__c LIMIT 1];
          WOM_UpdateWaitlistWrapper.RequestWrapper requestWrapper = buildUpdateWaitlistRequest();
          requestWrapper.salesforceId =  waitlistRecord.Id;
          test.startTest();
            WOM_API_Endpoint__mdt updateWaitlistEndpointInfo = new WOM_API_Endpoint__mdt( WOM_isnotlive__c = true,WOM_Mock_Request__c= '',WOM_Content_Type__c='',WOM_Mock_Response__c='{"entryId": "06aa98ff-e39d-4c9d-ae95-2839ae5ec7ez"}' );
            WOM_UpdateWaitlistAPIHttpCalloutMock mockCLass = new WOM_UpdateWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            HttpRequest updateWailistRequest = WOM_UpdateWaitlistAPI.buildUpdateWaitlistRequest(requestWrapper,updateWaitlistEndpointInfo);
            HttpResponse updateWailistResponse = WOM_UpdateWaitlistAPI.updateWaitlistHTTPCallOut(updateWailistRequest);
            String salesforceIntMessageId = WOM_APIHelper.buildIntMessage(WOM_APIHelper.TYPE_WOM_ADD_WAITLIST,Int_Values.STATUS_PENDING ,'', '' ,'','','', null);
            WOM_UpdateWaitlistAPI.parseUpdateWaitlistResponse(updateWailistResponse,updateWailistRequest,updateWaitlistEndpointInfo,salesforceIntMessageId,waitlistRecord.Id);            
            Int_Message__c intMessage = [Select id,Status__c from Int_Message__c limit 1];
            System.assertEquals('Successful',intMessage.Status__c, 'Add Waitlist Not Live test case failed');
          test.stopTest();
        }
    }
    
    
    /**
    * @description 
    * @author Lim Gabba | 12-12-2022 
    * @return WOM_UpdateWaitlistWrapper.RequestWrapper 
    **/
    public static WOM_UpdateWaitlistWrapper.RequestWrapper buildUpdateWaitlistRequest(){
        WOM_Waitlist__c waitlistRecord = [SELECT Id FROM WOM_Waitlist__c LIMIT 1];
        system.debug(System.LoggingLevel.DEBUG,'waitlistRecord==='+waitlistRecord); 
        WOM_UpdateWaitlistWrapper.RequestWrapper updateWaitlist = new WOM_UpdateWaitlistWrapper.RequestWrapper();
        updateWaitlist.entryId = 'd1ee58a9-f440-4d8d-b5b5-92001947b7f1';
        updateWaitlist.salesforceId = waitlistRecord.Id;
        updateWaitlist.storeCode  = 'AZP18';
        updateWaitlist.site =  '1234';
        updateWaitlist.journeyId = '123454';
        updateWaitlist.status = 'cancelled';
        updateWaitlist.arrivalId = '543216';
        updateWaitlist.arrivalETA  = '2020-04-23T12:10:00+00:00';
        updateWaitlist.tripStatus = 'arrived';
        updateWaitlist.tripStartTime = '2020-04-23T12:10:00+00:00';
        updateWaitlist.tripEndTime  = '2020-04-23T12:10:00+00:00';
        return updateWaitlist;
    }
    
    
}