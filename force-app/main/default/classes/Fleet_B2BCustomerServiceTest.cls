@isTest
public class Fleet_B2BCustomerServiceTest {    
    
    @testSetup static void setupData(){
       
        Id b2bContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'test Acc';
        acc.ECC_Account_Number__c = '01234';
        
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'test Acc2';
        acc2.ECC_Account_Number__c = '01236';
        insert acc2;
        
        Account acc3 = new Account();
        acc3.Name = 'test Acc3';
        //acc3.ECC_Account_Number__c = '01236';
        insert acc3;
        
        Contact con = new Contact();
        con.LastName = 'Test LN';
        con.FirstName = 'Test FN';
        con.Phone = '1231231231';
        con.Title = 'title';
        con.Email='test@g.com';
        con.Department='depert';
        con.AccountId = acc.Id;
        con.RecordTypeId = b2bContactRT;
        con.ECC_Is_Primary_Contact__c = True;
        con.ECC_Customer_Reference_Number__c = 'test con no';


        insert con;
                             
        Int_Message__c intMsg = new Int_Message__c();
        intMsg.Type__c = Int_Values.TYPE_B2BCUSTOMER_INCOMING;
        intMsg.Payload__c = 'data';
        intMsg.Status__c = Int_Values.STATUS_PENDING;
        insert intMsg; 
    }
    
    @isTest static void testUpdateB2BCustomerData(){
        
        Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc'];
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Blob requestBody = Blob.valueOf('{"eccId": "'+acc.ECC_Account_Number__c+'", "salesforceId": "'+acc.id+'", "accountManager": "04", '+
                                           '"state": "US","contacts": {"lastName":"testContact"}}');
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Base URL: ' + sfdcBaseURL );   
        
        RestRequest request = new RestRequest();
        request.requestUri = sfdcBaseURL+'/services/apexrest/b2bcustomer/';
        request.httpMethod = 'PUT';
        request.requestBody = requestBody;
        RestContext.request = request;       
       
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = acc.ECC_Account_Number__c;
        b2bModel.salesforceId = acc.id;
        b2bModel.accountManager = '04';
        b2bModel.state = 'AZ';
        b2bModel.creditLimit='1000.1';
        b2bModel.createdDate='20140821';
        b2bModel.poRequired='yes';
        b2bModel.invoiceCopy='yes';
        b2bModel.certificate='yes';
        
        Test.startTest();        
        Fleet_B2BCustomerService.updateB2BCustomerData();
        Fleet_B2BCustomerService.setSFError(intMsg, '', '');   
        Fleet_B2BCustomerService.processAccountData(b2bModel, intMsg);
        //Fleet_B2BCustomerService.processContactData(b2bModel, intMsg, acc.id);
        Fleet_B2BCustomerService.getB2BCustomerData('');
        Fleet_B2BCustomerService.buildB2BHttpReq('s');
        Fleet_B2BCustomerService.testCallGetAccount();
        Test.stopTest();
        
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        update intMsg;
        String payload;
        Fleet_B2BCustomerService.updateB2BCustomerDataBody('payload');
        
    }
    
    @isTest static void testUpdateB2BCustomerDataSync(){
        
        Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc3'];
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Blob requestBody = Blob.valueOf('{"eccId": "123456", "salesforceId": "'+acc.id+'", "accountManager": "04", '+
                                           '"state": "US","contacts": {"lastName":"testContact"}}');
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Base URL: ' + sfdcBaseURL );   
        
        RestRequest request = new RestRequest();
        request.requestUri = sfdcBaseURL+'/services/apexrest/b2bcustomer/';
        request.httpMethod = 'PUT';
        request.requestBody = requestBody;
        RestContext.request = request;       
       
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = '123456';
        b2bModel.salesforceId = acc.id;
        b2bModel.accountManager = '04';
        b2bModel.state = 'AZ';
        b2bModel.creditLimit='1000.1';
        b2bModel.createdDate='20140821';
        b2bModel.poRequired='yes';
        b2bModel.invoiceCopy='yes';
        b2bModel.certificate='yes';
        
        Test.startTest();        
        Fleet_B2BCustomerService.updateB2BCustomerData();
        Fleet_B2BCustomerService.setSFError(intMsg, '', '');   
        Fleet_B2BCustomerService.processAccountData(b2bModel, intMsg);
        //Fleet_B2BCustomerService.processContactData(b2bModel, intMsg, acc.id);
        Fleet_B2BCustomerService.getB2BCustomerData('');
        Fleet_B2BCustomerService.buildB2BHttpReq('s');
        Fleet_B2BCustomerService.testCallGetAccount();
        Test.stopTest();
        
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        update intMsg;
        String payload;
        Fleet_B2BCustomerService.updateB2BCustomerDataBody('payload');
        
    }
    
    @isTest static void testUpdateB2BCustomerDataFailure(){
        
        //Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc'];
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Blob requestBody = Blob.valueOf('{"eccId": "123456", "salesforceId": "0015900000Vv5rcAAB", "accountManager": "04", '+
                                           '"state": "US","contacts": {"lastName":"testContact"}}');
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Base URL: ' + sfdcBaseURL );   
        
        RestRequest request = new RestRequest();
        request.requestUri = sfdcBaseURL+'/services/apexrest/b2bcustomer/';
        request.httpMethod = 'PUT';
        request.requestBody = requestBody;
        RestContext.request = request;       
       
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = '123456';
        b2bModel.salesforceId = '0015900000Vv5rcAAB';
        b2bModel.accountManager = '04';
        b2bModel.state = 'AZ';
        b2bModel.creditLimit='1000.1';
        b2bModel.createdDate='20140821';
        b2bModel.poRequired='yes';
        b2bModel.invoiceCopy='yes';
        b2bModel.certificate='yes';
        
        Test.startTest();        
        Fleet_B2BCustomerService.updateB2BCustomerData();
        Fleet_B2BCustomerService.setSFError(intMsg, '', '');   
        Fleet_B2BCustomerService.processAccountData(b2bModel, intMsg);
        //Fleet_B2BCustomerService.processContactData(b2bModel, intMsg, acc.id);
        Fleet_B2BCustomerService.getB2BCustomerData('');
        Fleet_B2BCustomerService.buildB2BHttpReq('s');
        Fleet_B2BCustomerService.testCallGetAccount();
        Test.stopTest();
        
        intMsg.Status__c = Int_Values.STATUS_SUCCESSFUL;
        update intMsg;
        String payload;
        Fleet_B2BCustomerService.updateB2BCustomerDataBody('payload');
        
    }
    
    @isTest static void testProcessAccountData(){
        Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc'];
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = acc.ECC_Account_Number__c;
        b2bModel.salesforceId = 'testIDAcc123';
        b2bModel.accountManager = '04';
        b2bModel.state = 'AZ';

        Fleet_B2BCustomerService.processAccountData(b2bModel, intMsg);
    }
    
    @isTest static void testProcessAccountDataAccNoNull(){
        Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc'];
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.salesforceId = 'testIDAcc123';
        b2bModel.accountManager = '04';
        b2bModel.state = 'AZ';

        Fleet_B2BCustomerService.processAccountData(b2bModel, intMsg);
    }
    
    @isTest static void testPayloadEmpty(){
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];

       
        Test.startTest();      
        String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Base URL: ' + sfdcBaseURL );   
        
        RestRequest request = new RestRequest();
        request.requestUri = sfdcBaseURL+'/services/apexrest/b2bcustomer/';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf('');
        RestContext.request = request;
        Fleet_B2BCustomerService.updateB2BCustomerData();
        Test.stopTest();
    }
    
    @isTest static void testProcessContactData(){
        Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc'];
        
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = acc.ECC_Account_Number__c;
        b2bModel.salesforceId = acc.id;
        b2bModel.accountManager = '04';

        
        Fleet_B2BCustomerModel.Contacts con = new Fleet_B2BCustomerModel.Contacts();
        con.lastName = 'test Last Name';
        con.contactPersonId = 'test contact person id';
        List<Fleet_B2BCustomerModel.Contacts> contacts = new List<Fleet_B2BCustomerModel.Contacts>();
        contacts.add(con);
         
        b2bModel.contacts = contacts;
        
       Fleet_B2BCustomerService.processContactData(b2bModel, intMsg, acc.id);
        
        
    }
    
    @isTest static void testProcessContactDataCatch(){
        //Account acc = [select id, name, ECC_Account_Number__c from Account where name='test Acc1'];
        Account acc = new Account();
        acc.Name = 'test Acc1';
        acc.ECC_Account_Number__c = '01235';
        insert acc;
        
        Int_Message__c intMsg = [select id, Type__c, Payload__c, Status__c from Int_Message__c where Type__c = :Int_Values.TYPE_B2BCUSTOMER_INCOMING];
        Fleet_B2BCustomerModel b2bModel = new Fleet_B2BCustomerModel();
        b2bModel.eccId = acc.ECC_Account_Number__c;
        b2bModel.salesforceId = acc.id;
        b2bModel.accountManager = '04';
        
        
        Fleet_B2BCustomerModel.Contacts con = new Fleet_B2BCustomerModel.Contacts();
        con.lastName = 'test Last Name';
        con.contactPersonId = 'test contact person id';
        List<Fleet_B2BCustomerModel.Contacts> contacts = new List<Fleet_B2BCustomerModel.Contacts>();
        contacts.add(con);
        b2bModel.contacts = contacts;  
        Id accId;
        Fleet_B2BCustomerService.processContactData(b2bModel, intMsg, accId);        
    }
    @isTest static void getTruncatedEmail(){
       Fleet_B2BCustomerModel.getTruncatedEmail('abc@gmail.com', 'yes');
       Fleet_B2BCustomerModel.getTruncatedEmail(null, ''); 
    }    
    @isTest static void testGetSerializedModelForContactData(){
        Account acc = new Account();
        acc.Name = 'test Acc1';
        acc.ECC_Account_Number__c = '01235';
        insert acc;
         
       Contact c=new Contact();
        c.AccountId=acc.Id;
        c.LastName='test';   
        Fleet_B2BCustomerModel.getSerializedModelFromContact(c);
    }
}