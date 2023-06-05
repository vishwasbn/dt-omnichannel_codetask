@isTest()
public class Fleet_CustomerRelationshipSurveyTest {
    
    @testSetup static void createTestClassData() {
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
        
        Id recordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        Account acc = new Account(
            Name='Test Account',
            Fleet_Account_Status__c='Customer',
            RecordTypeId = recordTypeId,
            SAP_Created_Date__c = Date.today()
        );
        insert acc;

        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id,
            Relationship__c = true
        );
        insert c;
        
        acc.Fleet_Primary_Contact__c = c.Id;
        update acc;
    }
    
    static testMethod void testGetAccount() {
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.StartTest();
        Fleet_CustomerRelationshipSurveyBatch testsche = new Fleet_CustomerRelationshipSurveyBatch();
        String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();
    }
    
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
}