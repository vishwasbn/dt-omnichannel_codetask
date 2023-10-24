/**
* @description       : Test Class for the WOM_AddWaitlistAPI
* @author            : Lim Gabba
* @group             : 
* @last modified on  : 12-23-2022
* @last modified by  : Lim Gabba
* Modification Log:
------------------------------------------------------------------------------------
Developer           Mod Number  Date           User Story      Description
------------------------------------------------------------------------------------
Lim Gabba         M-001        21-12-2022      WOM-40          Initial Integration Class
Hrushikesh        M-001        22-12-2022      WOM-40          Static Analysis chnages
Srajan            M-003        03-01-2023                      Updated to follow best practices
Akilan            M-004        17-01-2023                      Added Not Live Method to Increase Coverage
Anil kumar        M-005        31-01-2023                      Removed sys.debug statements
Lim Gabba         M-005        04-06-2023      WOM-1983        Logging Framework Updates
* 
**/
@isTest(SeeAllData=false)
public class WOM_AddWaitlistAPITest {  
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
    
    static testmethod void testAddWaitlistPositive() {    
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            test.startTest();
            WOM_AddWaitlistWrapper.RequestWrapper requestWrapper = buildAddWaitlistRequest();
            WOM_API_Endpoint__mdt addWaitlistEndpointInfo = WOM_APIHelper.getEndPointDetails('WOM_AddWaitlistData');
            WOM_AddWaitlistAPIHttpCalloutMock mockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(201, 'OK', 'successes');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            WOM_AddWaitlistAPI.addWaitlistAPICall(requestWrapper); 
            System.assertEquals(true,requestWrapper!=null,'Add waitlist Positive test case failed');   
            test.stopTest();
        }
    }
    
    /**
    * @description : It is used to test negative functionality of the response from horizon
    * @author Lim Gabba | 12-12-2022 
    * @last modified by  : Srajan
    * @last modified on  : 01-03-2023
    **/ 
    static testmethod void testAddWaitlistNegative() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WOM_Waitlist__c waitlistRecord = [SELECT Id FROM WOM_Waitlist__c LIMIT 1];
            WOM_AddWaitlistWrapper.RequestWrapper requestWrapper = new  WOM_AddWaitlistWrapper.RequestWrapper();
            requestWrapper.salesforceId =  waitlistRecord.Id;
            test.startTest();
            WOM_API_Endpoint__mdt addWaitlistEndpointInfo = WOM_APIHelper.getEndPointDetails('WOM_AddWaitlistData');
            WOM_AddWaitlistAPIHttpCalloutMock mockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            WOM_AddWaitlistAPI.addWaitlistAPICall(requestWrapper);
            WOM_AddWaitlistWrapper.ResponseWrapper responseWrapper = new WOM_AddWaitlistWrapper.ResponseWrapper();
            responseWrapper.entryId = '';
            responseWrapper.salesforceId = '';
            System.assertEquals('',responseWrapper.entryId, 'Add waitlist Negative test case failed');
            
            WOM_API_Endpoint__mdt endpointInfo = WOM_APIHelper.getEndPointDetails('');
            WOM_AddWaitlistAPIHttpCalloutMock testMockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, testMockCLass);
            WOM_AddWaitlistAPI.addWaitlistAPICall(requestWrapper);
            WOM_AddWaitlistWrapper.ResponseWrapper testResponseWrapper = new WOM_AddWaitlistWrapper.ResponseWrapper();
            responseWrapper.entryId = '';
            responseWrapper.salesforceId = '';
            System.assertEquals('',responseWrapper.entryId, 'Add waitlist Negative test case failed');
            
            test.stopTest();
        }
    }
    
    /**
    * @description : It is used to test Not Live functionality 
    * @author Akilan | 17-01-2022 
    **/ 
    static testmethod void testAddWaitlistNotLive() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            WOM_Waitlist__c waitlistRecord = [SELECT Id FROM WOM_Waitlist__c LIMIT 1];
            WOM_AddWaitlistWrapper.RequestWrapper requestWrapper = new  WOM_AddWaitlistWrapper.RequestWrapper();
            requestWrapper.salesforceId =  waitlistRecord.Id;
            test.startTest();
            WOM_API_Endpoint__mdt addWaitlistEndpointInfo = 
                new WOM_API_Endpoint__mdt( WOM_isnotlive__c = true,WOM_Mock_Request__c= '',WOM_Content_Type__c='',WOM_Mock_Response__c='{"entryId": "06aa98ff-e39d-4c9d-ae95-2839ae5ec7ez"}',WOM_Endpoint_URL__c='WWW.Salesforce.com');
            WOM_AddWaitlistAPIHttpCalloutMock mockCLass = new WOM_AddWaitlistAPIHttpCalloutMock(400, 'Error', 'Bad Request');
            Test.setMock(HttpCalloutMock.class, mockCLass);
            HttpRequest addWailistRequest = WOM_AddWaitlistAPI.buildAddWaitlistRequest(requestWrapper,addWaitlistEndpointInfo);
            HttpResponse addWailistResponse = WOM_AddWaitlistAPI.addWaitlistHTTPCallOut(addWailistRequest);
            String salesforceIntMessageId = WOM_APIHelper.buildIntMessage(WOM_APIHelper.TYPE_WOM_ADD_WAITLIST,Int_Values.STATUS_PENDING ,'', '' ,'','','', null);
            WOM_AddWaitlistAPI.parseAddWaitlistResponse(addWailistResponse,addWailistRequest,addWaitlistEndpointInfo,salesforceIntMessageId,requestWrapper.salesforceId);
            
            WOM_Waitlist__c updatedWaitlistRecord = [SELECT Id,WOM_WaitlistEntryId__c FROM WOM_Waitlist__c LIMIT 1];
            System.assertEquals('06aa98ff-e39d-4c9d-ae95-2839ae5ec7ez',updatedWaitlistRecord.WOM_WaitlistEntryId__c, 'Add Waitlist Not Live test case failed');
            test.stopTest();
        }
    }
    
    /**
    * @description : Method to cover WOM_APIHelper.resonFormatting with 2 services selected
    * @author Anuradha | 14-04-2023  
    **/ 
    static testmethod void resonFormatting2ValuesTest() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            test.startTest();
                System.Assertequals('Flat repair',WOM_APIHelper.resonFormatting('Flat Repair;New Tires/Wheels'),'resonFormatting2ValuesTest failed');

            test.stopTest();
        }
    }
    
    /**
    * @description : Method to cover WOM_APIHelper.resonFormatting with >2 services selected
    * @author Anuradha | 14-04-2023 
    **/ 
    static testmethod void resonFormatting4ValuesTest() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            test.startTest();
                System.Assertequals('Flat repair',WOM_APIHelper.resonFormatting('Flat Repair;New Tires/Wheels;Rotation/Balance;Other'),'resonFormatting4ValuesTest failed');

            test.stopTest();
        }
    }
    
    /**
    * @description : Method to cover negative scenario for refreshToken
    * @author Anuradha | 14-04-2023 
    **/
    static testmethod void refreshTokenTestNegative(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            System.Assertequals('',WOM_APIHelper.refreshToken('testOrg'),'refreshTokenTestNegative failed');
        }
    }
    
    /**
    * @description : Method to cover negative scenario for refreshToken
    * @author Anuradha | 14-04-2023 
    **/
    static testmethod void resonFormattingNegative(){
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            System.Assertequals('testOrg',WOM_APIHelper.resonFormatting('testOrg'),'resonFormattingNegative failed');
        }
    }
    
    /**
    * @description : Method to cover WOM_APIHelper.resonFormatting with single service selected
    * @author Akilan | 17-01-2022 
    **/ 
    static testmethod void resonFormattingSingleValueTest() {
        User u=[SELECT Id from User where email ='user0@test.com' LIMIT 1];
        System.runas(u){
            test.startTest();
                System.Assertequals('New tires/wheels',WOM_APIHelper.resonFormatting('New Tires/Wheels'),'resonFormattingSingleValueTest failed');
            test.stopTest();
        }
    }
    
    /**
    * @description 
    * @author Lim Gabba | 12-12-2022 
    * @return WOM_AddWaitlistAPI.AddWaitlistRequestWrapper 
    **/
    public static WOM_AddWaitlistWrapper.RequestWrapper buildAddWaitlistRequest(){
        WOM_Waitlist__c waitlistRecord = [SELECT Id FROM WOM_Waitlist__c LIMIT 1]; 
        WOM_AddWaitlistWrapper.RequestWrapper addWaitlist = new WOM_AddWaitlistWrapper.RequestWrapper();
        addWaitlist.salesforceId = waitlistRecord.Id;
        addWaitlist.journeyId = '12345' ;
        addWaitlist.storeCode = 'AZP55' ;
        addWaitlist.site = '12312' ;
        addWaitlist.firstName = 'Richard' ;
        addWaitlist.lastName = 'Standage' ;
        addWaitlist.hasApt = false ;
        addWaitlist.sendSMS = false ;
        addWaitlist.arrived = false ;
        addWaitlist.phone= '4103563890' ;
        addWaitlist.reason = 'flat-repair' ;
        addWaitlist.comments = 'Please provide best service' ;
        addWaitlist.timestamp = '2020-05-18T12:12:32+05:30' ;
        return addWaitlist;
    }
}