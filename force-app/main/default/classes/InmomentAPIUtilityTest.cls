@isTest
public class InmomentAPIUtilityTest{
    private class RestMock implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
         String fullJson = '{"succeeded":true,"message":"40f82482-2ca5-4327-85ec-e0279eea4378"}';
         HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    
    
    
    static testMethod void validateAPIUtility(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
                
        InmomentSetting__c ins = new InmomentSetting__c();
        ins.AT_Gateway_Alias__c = 'test';
        ins.AuthUrl__c = 'test2';
        ins.Client_ID__c = 'test345';
        ins.Client_Secret__c = 'test5';
        ins.DT_Gateway_Alias__c = 'test';
        ins.Password__c = 'test09';
        ins.SurveyURL__c = 'test/docs';
        ins.Username__c = 'testStage';
        insert ins;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'b2b Contact';
        insert con;
        
        Test.startTest();
        InmomentAPIUtility.sendSurvey(con.id,'Test','Exit');
        Test.stopTest();
        
        Contact cont = [SELECT FirstName from Contact WHERE Id=:con.id];
        System.debug(cont.FirstName);
        System.assertEquals(cont.FirstName, 'Test');
    }
    
    static testMethod void validateAPIUtilityScheduler(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
                
        InmomentSetting__c ins = new InmomentSetting__c();
        ins.AT_Gateway_Alias__c = 'test';
        ins.AuthUrl__c = 'test2';
        ins.Client_ID__c = 'test345';
        ins.Client_Secret__c = 'test5';
        ins.DT_Gateway_Alias__c = 'test';
        ins.Password__c = 'test09';
        ins.SurveyURL__c = 'test/docs';
        ins.Username__c = 'testStage';
        insert ins;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'b2b Contact';
        insert con;
        
        Test.startTest();
        String jobId = System.schedule('testBasicScheduledApex', '0 0 0 3 9 ? 2023', new InmomentAccessTokenScheduler());
        Test.stopTest();
        
        Contact cont = [SELECT FirstName from Contact WHERE Id=:con.id];
        System.debug(cont.FirstName);
        System.assertEquals(cont.FirstName, 'Test');
    }
    
    static testMethod void validateContactHandler(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
        InmomentSetting__c ins = new InmomentSetting__c();
        ins.AT_Gateway_Alias__c = 'test';
        ins.AuthUrl__c = 'test2';
        ins.Client_ID__c = 'test345';
        ins.Client_Secret__c = 'test5';
        ins.DT_Gateway_Alias__c = 'test';
        ins.Password__c = 'test09';
        ins.SurveyURL__c = 'test/docs';
        ins.Username__c = 'testStage';
        insert ins;
        
        Account newAccount = new Account(Name = 'Test Account12345678910',ECC_Account_Number__c = '40177',Fleet_Account_Status__c = 'Customer');
        insert newAccount; 
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'b2b Contact';
        insert con;
        
        Contact con2 = new Contact();
        con2.FirstName = 'Test234';
        con2.LastName = 'b2b Contact';
        con2.Exit__c = true;
        con2.Onboarding__c = true;
        con2.Post_Visit__c = true;
        con2.Relationship__c = true;
        con2.Survey_Response__c = '{"succeeded":false,"message":"3cd14757-901b-4cbb-a882-a1d14a688e21"}\n\n{"succeeded":false,"message":"You must provide a non-empty recipient email address.","failureType":"invalid_request"}';
        insert con2;
        
        Contact b2bContact = new Contact();
        b2bContact.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        b2bContact.FirstName = 'Test';
        b2bContact.LastName = 'b2b Contact';
        b2bContact.AccountId = newAccount.id;
        insert b2bContact;
        
        Map<Id,Contact> conmap = new Map<Id,contact>();
        conmap.put(b2bContact.Id,b2bContact);
        
        Map<Id, Contact> oldMap = new  Map<Id, Contact>();
        oldMap.put(con.Id, con);
        
       
        Test.startTest();
        Fleet_ContactTriggerHandler.handle(oldMap, oldMap, System.TriggerOperation.BEFORE_DELETE);
        Fleet_ContactTriggerHandler.processDeleteContactForECC(conmap);
        Fleet_ContactTriggerHandler.sendOutboundForContactECCSynch(b2bContact);
        Fleet_ContactTriggerHandler.sendOutboundForAccountECCSynch(newAccount.id);
        Test.stopTest();
    }   
    
    static testMethod void validateContactHandlerv2(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
        InmomentSetting__c ins = new InmomentSetting__c();
        ins.AT_Gateway_Alias__c = 'test';
        ins.AuthUrl__c = 'test2';
        ins.Client_ID__c = 'test345';
        ins.Client_Secret__c = 'test5';
        ins.DT_Gateway_Alias__c = 'test';
        ins.Password__c = 'test09';
        ins.SurveyURL__c = 'test/docs';
        ins.Username__c = 'testStage';
        insert ins;
        
        Account newAccount = new Account(Name = 'Test Account12345678910',ECC_Account_Number__c = '40177',Fleet_Account_Status__c = 'Customer');
        insert newAccount; 
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'b2b Contact';
        insert con;
        
        Contact con2 = new Contact();
        con2.FirstName = 'Test234';
        con2.LastName = 'b2b Contact';
        con2.Exit__c = true;
        con2.Onboarding__c = true;
        con2.Post_Visit__c = true;
        con2.Relationship__c = true;
        con2.Survey_Response__c = '{"succeeded":false,"message":"3cd14757-901b-4cbb-a882-a1d14a688e21"}\n\n{"succeeded":false,"message":"You must provide a non-empty recipient email address.","failureType":"invalid_request"}';
        insert con2;
        
        Contact b2bContact = new Contact();
        b2bContact.RecordTypeId = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        b2bContact.FirstName = 'Test';
        b2bContact.LastName = 'b2b Contact';
        b2bContact.AccountId = newAccount.id;
        insert b2bContact;
        
        Map<Id,Contact> conmap = new Map<Id,contact>();
        conmap.put(b2bContact.Id,b2bContact);
        
        Map<Id, Contact> oldMap = new  Map<Id, Contact>();
        oldMap.put(con.Id, con);
        
       
        Test.startTest();
        Database.executeBatch(new BatchSendInmomentSurvey('1'), 1);
        Test.stopTest();
    }   
}