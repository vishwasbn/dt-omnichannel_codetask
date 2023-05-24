@isTest (seeAllData = false)
public class Fleet_InvoiceIntegrationUtil_Test {

   
    @IsTest 
    public static void testAccoutOutboundUpdatesSet1() 
    {
        //---This tests creating an Account, setting values and then checking if the updates are processed

        Account acct = getNewCustomerAccount();

        //---Have 2 Specialists, one without ECC Id and one with ECC Id
        User specialist1 = getNewUser('Super1', 'Specialist', 'Fleet Sales User');
        User specialist2 = getNewUser('Super2', 'Specialist', 'Fleet Sales User');
        specialist2.Fleet_ECC_Key__c = '456';
        update specialist2;

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.ECC_Account_Number__c = '1234';
        acct.Fleet_Specialist__c = specialist1.Id;
        update acct;

        //---Change the Notes, testing out the split functions
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        acct.Fleet_Specialist__c = specialist2.Id;  //---Switch to Specialist with ECC Id
        update acct;

        //---Change the Public Notes
        acct.Fleet_Public_Notes__c = 'Note1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Private_Notes__c = 'Note1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = false;
        acct.Invoice_Copy_Sent__c = false;
        acct.Fleet_Specialist__c = specialist2.Id;
        update acct;

        List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        //System.assert(intMessageList.size() > 0, 'Expecting Integration Messages');
        
        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutOutboundUpdatesSet2() 
    {
        //---This tests creating an Account, and a Contact and then converting

        Account acct = getNewCustomerAccount();

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.ECC_Account_Number__c = '1234';
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        update acct;

        Contact contact = getNewCustomerContact(acct.Id);

        List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        //System.assert(intMessageList.size() > 0, 'Expecting there to be Integration Messages');
        
        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutCOutboundUpdatesSet3() 
    {
        //---This tests creating an Account, and a Contact and then converting

        Account acct = getNewCustomerAccount();

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.ECC_Account_Number__c = '1234';
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        update acct;

        Contact contact = getNewCustomerContact(acct.Id);
    
        contact.ECC_Contact_Person_Id__c = '1234';
        contact.Title = 'CEO';
        contact.Email = 'test@123.com';
        contact.Phone = '602-555-1234';
        contact.ECC_Is_Primary_Contact__c = true;
        contact.ECC_Customer_Reference_Number__c = '123';
        update contact;

        contact.FirstName = 'Test';
        contact.LastName = 'Contact';
        contact.Title = 'CEO';
        contact.Phone = '602-555-1235';
        contact.Email = 'test@123.com';
        contact.ECC_Is_Primary_Contact__c = false;
        contact.ECC_Customer_Reference_Number__c = '1234';
        update contact;

        List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        //System.assert(intMessageList.size() > 0, 'Expecting there to be Integration Messages');

        //---Testing Delete
        delete contact;
        
        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutInboundSet1() 
    {
        //---This tests creating an Account, and an incoming update

        Account acct = getNewCustomerAccount();

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.ECC_Account_Number__c = '1234';
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        update acct;

        Contact contact = getNewCustomerContact(acct.Id);

        List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        //System.assert(intMessageList.size() > 0, 'Expecting there to be Integration Messages');
        
        //---Handle incoming update to the Account
        String payload = getAccountUpdateJSON( '1234', acct.Id, '123456');
        Fleet_B2BCustomerService.B2BReponse response = Fleet_B2BCustomerService.updateB2BCustomerDataBody(payload);

        Fleet_B2BCustomerService.testCallGetAccount();
        //Fleet_B2BCustomerService.updateB2BCustomerData();
        Fleet_B2BCustomerService.setSFError(new Int_Message__c(), 'loc', 'Error');

        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutInboundSet2() 
    {
        //---This tests creating an Account, and an incoming update

        Account acct = getNewCustomerAccount();

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        update acct;

        Contact contact = getNewCustomerContact(acct.Id);
        
        //---Handle incoming update to the Account
        String payload = getAccountUpdateJSON( '1234', acct.Id, '123456');
        Fleet_B2BCustomerService.B2BReponse response = Fleet_B2BCustomerService.updateB2BCustomerDataBody(payload);

        List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        System.assert(intMessageList.size() > 0, 'Expecting there to be Integration Messages');

        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutContactECCSynch() 
    {
        //---This tests creating an Account, and an incoming update

        Account acct = getNewCustomerAccount();

        Test.startTest();

        //---Convert to Customer
        acct.Fleet_Account_Status__c = 'Customer';
        acct.Fleet_Public_Notes__c = 'Public Note #1 Test  Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test';
        acct.Fleet_Private_Notes__c = 'Private Note #1 12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
        acct.Fleet_Use_Certificates__c = true;
        acct.Invoice_Copy_Sent__c = true;
        update acct;

        Fleet_AccountTriggerHandler.sendOutboundForAccountECCSynch(acct);

        Contact contact = getNewCustomerContact(acct.Id);

        Fleet_ContactTriggerHandler.sendOutboundForAccountECCSynch(acct.Id);
        
        //List<Int_Message__c> intMessageList = [SELECT Id FROM Int_Message__c];
        //System.assert(intMessageList.size() > 0, 'Expecting there to be Integration Messages');

        Test.stopTest();
    }

    @IsTest 
    public static void testAccoutOutbound1() 
    {
        //---This tests calling out for data

        Test.startTest();

        Fleet_B2BCustomerService.getB2BCustomerData('1234');

        Test.stopTest();
    }

    @IsTest 
    public static void testSetupBatchSchedule() 
    {
        //---This tests calling out for data

        Test.startTest();
        Fleet_B2BCustomerUpdateBatch.isTest = true;
        Fleet_B2BCustomerUpdateBatch.setupSchedule();

        Test.stopTest();
    }

    @IsTest 
    public static void testSetupBatchRun() 
    {
        //---This tests calling out for data

        Test.startTest();

        Fleet_B2BCustomerUpdateBatch.process();

        Test.stopTest();
    }

    @IsTest 
    public static void testInvoiceService() 
    {
        //---This tests calling out for data

        Test.startTest();

        Fleet_InvoiceService.isTest = true;
        
        Fleet_InvoiceService.testPayload = Fleet_CarDetailModelTest.getJSON();
        Fleet_InvoiceService.testCallDetail();

        Fleet_InvoiceService.testPayload = Fleet_CarSummaryModelTest.getJSON();
        Fleet_InvoiceService.testCallSummary();

        Fleet_InvoiceService.testCallSearch();

        HttpRequest req = Fleet_InvoiceService.buildCARHttpReq('TestURL');
        System.assert(req != null, 'Expecting Integration Messages');

        Test.stopTest();
    }

    @IsTest 
    public static void testMockAPI() 
    {
        //---This tests calling out for data

        Test.startTest();

        Fleet_Mock_InvoiceAPI.mockInvoiceDetailAPI();
        Fleet_Mock_InvoiceAPI.mockInvoiceSummaryAPI();

        Test.stopTest();
    }

    @IsTest 
    public static void testECCService() 
    {
        //---This tests calling out for data

        Int_Message__c intMsg = new Int_Message__c();

        Test.startTest();

        Fleet_ECCService.handleSFException(intMsg, null);
        Fleet_ECCService.handleExternalError(intMsg, 'error');

        Test.stopTest();
    }

    @IsTest 
    public static void testECCService2() 
    {
        //---This tests calling out for data

        Int_Message__c intMsg = new Int_Message__c();

        Test.startTest();

        String testJSON =  getAccountUpdateJSON('x', 'x', 'x');

        List<Id> messageIdList = new List<Id>();
        Fleet_ECCService.sendRetryMessges(messageIdList);
        Fleet_ECCService.recordRetry(intMsg);
        Fleet_ECCService.parseAndReadResults(intMsg,testJSON);

        Test.stopTest();
    }

    @IsTest 
    public static void testECCServiceRetry() 
    {
        //---This tests calling out for data

        Int_Message__c newMsg = new Int_Message__c();
        newMsg.Type__c = Int_Values.TYPE_ACCOUNT_ECC;
        newMsg.Object_Type__c = 'Account';
        newMsg.Status__c = Int_Values.STATUS_ERROR;
        insert newMsg;

        Test.startTest();

        String testJSON =  getAccountUpdateJSON('x', 'x', 'x'); 

        List<Id> messageIdList = new List<Id>();
        messageIdList.add(newMsg.Id);

        Fleet_ECCService.sendRetryMessges(messageIdList);
              
        Fleet_ECCService.parseAndReadResults(newMsg,testJSON);

        Test.stopTest();
    }

    @IsTest 
    public static void testInvoiceIntegrationUtil() 
    {
        //---This tests calling out for data
        Fleet_InvoiceIntegrationUtil.getSettingBooleanValue('test');
        Int_Message__c intMsgBToken = new Int_Message__c(Type__c=Int_Values.TYPE_FLEET_OAUTH, Status__c=Int_Values.STATUS_PENDING);
        Fleet_InvoiceIntegrationUtil.getBearerToken(intMsgBToken);
        Int_Message__c intMsg = new Int_Message__c();

        Test.startTest();
        Fleet_InvoiceIntegrationUtil.recordSuccess(intMsg);
        Fleet_InvoiceIntegrationUtil.recordError(intMsg, 'xxx');

        Fleet_InvoiceIntegrationUtil.recordNoToken(intMsg, 'x');
        Fleet_InvoiceIntegrationUtil.handleExternalError(intMsg, 'x');

        String body = 'x';
        Fleet_InvoiceIntegrationUtil.recordGetResults(intMsg, body);

        body = '';
        Fleet_InvoiceIntegrationUtil.recordGetResults(intMsg, body);


        Integer testVal1 = Fleet_InvoiceIntegrationUtil.getSettingIntValue('No Value');
        Integer testVal2 = Fleet_InvoiceIntegrationUtil.getSettingIntValue('ECC_Disable_All_Outgoing');  //---This is not an integer value
        String bToken1 = Fleet_InvoiceIntegrationUtil.parseBToken(intMsg, '{"access_token": "00D3"}');
        String bToken2 = Fleet_InvoiceIntegrationUtil.parseBToken(intMsg, '{"error": "No token"}');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FleetExperienceAPI' + 'endUrl');
        req.setMethod('GET');
        Fleet_InvoiceIntegrationUtil.getRequestBody( req, intMsgBToken);
        Test.stopTest();
    }

    @isTest static void HttpReqSendTest() {
        Int_Message__c newMsg = new Int_Message__c();
        newMsg.Type__c = Int_Values.TYPE_ACCOUNT_ECC;
        newMsg.Object_Type__c = 'Account';
        newMsg.Status__c = Int_Values.STATUS_ERROR;
        insert newMsg;
        
        Test.startTest();
        Fleet_InvoiceIntegrationUtil.HttpReqSend(newMsg.Id);
        Test.stopTest();
    }

    //---Build a new Customer Account
    public static Account getNewCustomerAccount()
    {
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        //---Create the new Prospect
        Account acct = new Account(RecordTypeId = b2bRT, Name = 'Big Dog', Fleet_Account_Status__c='Prospect');
        insert acct;

        return acct;
    }

    //---Build a new Account Contact
    public static Contact getNewCustomerContact(Id accountId)
    {
        Id b2bRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get('B2B_Contact').getRecordTypeId();

        Contact cont = new Contact();
        cont.AccountId = accountId;
        cont.RecordTypeId = b2bRT;
        cont.FirstName = 'Test';
        cont.LastName = 'Contact';

        insert cont;

        return cont;
    }

    public static User getNewUser(String firstName, String lastName, String profileName)
    {
        User newUser = new User();
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Email = 'test@discounttire.com';
        newUser.Username = 'test@discounttire.com' + System.currentTimeMillis();
        newUser.CompanyName = 'TEST';
        newUser.Title = 'title';
        newUser.Alias = 'alias';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
  
        insert newUser;

        return newUser;
    }

    //---Get Account udpate 
    public static String getAccountUpdateJSON(String eccId, String sfId, String contactEccId)
    {
        String json = '{'+
        '  \"eccId\": \"' + eccId + '",'+
        '  \"country\": \"US\",'+
        '  \"countryDescription\": \"USA\",'+
        '  \"companyName\": \"WHEELS AMERICA-HOUSTON\",'+
        '  \"companyName2\": \"\",'+
        '  \"city\": \"HOUSTON\",'+
        '  \"postalCode\": \"77092-3807\",'+
        '  \"state\": \"TX\",'+
        '  \"street\": \"4750 SHERWOOD LN\",'+
        '  \"phoneNumber\": \"713-686-1311\",'+
        '  \"industryKey\": \"Z03\",'+
        '  \"industryKeyDescription\": \"Automobile Services\",'+
        '  \"createdDate\": \"20140722\",'+
        '  \"groupKey\": \"DT FLEET\",'+
        '  \"corporateGroupDescription\": \"DT FLEET CHARGE ACCOUNTS\",'+
        '  \"certificate\": \"01\",'+
        '  \"certificateDescription\": \"Charge Cert.\",'+
        '  \"invoiceCopy\": \"01\",'+
        '  \"invoiceCopyDescription\": \"INVOICE COPY\",'+
        '  \"poRequired\": \"01\",'+
        '  \"poRequiredDescription\": \"PO Required\",'+
        '  \"accountType\": \"04\",'+
        '  \"accountTypeDescription\": \"DT FLEET\",'+
        '  \"accountPaymentType\": \"01\",'+
        '  \"accountPaymentTypeDescription\": \"AR CHARGE\",'+
        '  \"accountManager\": \"01\",'+
        '  \"accountManagerDescription\": \"KEVIN GATTI\",'+
        '  \"accountCompany\": \"06\",'+
        '  \"accountCompanyDescription\": \"FLEET\",'+
        '  \"autoIntegrate\": \"02\",'+
        '  \"autoIntegrateDescription\": \"No\",'+
        '  \"creditLimit\": \"10000.00\",'+
        '  \"taxClassification\": \"1\",'+
        '  \"taxClassificationDescription\": \"Taxable\",'+
        '  \"street4\": \"STE 301\",'+
        '  \"postingBlockForCompanyCode\": \"X\",'+
        '  \"accountingClerkAbbreviation\": \"02\",'+
        '  \"termsOfPaymentKey\": \"NT60\",'+
        '  \"termsOfPaymentKeyDescription\": \"\",'+
        '  \"salesforceId\": \"' + sfId + '\",'+
        '  \"billingBlockforSalesArea\": \"01\",'+
        '  \"billingBlockforSalesAreaDescription\": \"Past Due\",'+
        '  \"contacts\": ['+
        '    {'+
        '      \"contactPersonId\": \"' + contactEccId + '\",'+
        '      \"firstName\": \"Contact\",'+
        '      \"lastName\": \"Testing1\",'+
        '      \"department\": \"0015\",'+
        '      \"departmentDescription\": \"Fleet CRM\",'+
        '      \"phoneNumber\": \"480-276-7777\",'+
        '      \"customerReferenceNumber\": \"Testing1\",'+
        '      \"primaryContactIndicator\": \"01\",'+
        '      \"primaryContactIndicatorDescription\": \"SPOC Purchasiing\",'+
        '      \"title\": \"Title1\",'+
        '      \"emailAddress\": \"testing.contact@discounttire.com\"'+
        '    }'+
        '  ],'+
        '  \"invoiceARRequiredFields\": ['+
        '    {'+
        '      \"characteristicValueAUSP\": \"01\",'+
        '      \"characteristicValueDescriptioinCAWNT\": \"DRIVER NAME\",'+
        '      \"objectKeyINOB\": \"0000019926\"'+
        '    },'+
        '    {'+
        '      \"characteristicValueAUSP\": \"02\",'+
        '      \"characteristicValueDescriptioinCAWNT\": \"COMPANY NAME\",'+
        '      \"objectKeyINOB\": \"0000019926\"'+
        '    },'+
        '    {'+
        '      \"characteristicValueAUSP\": \"12\",'+
        '      \"characteristicValueDescriptioinCAWNT\": \"VIN #\",'+
        '      \"objectKeyINOB\": \"0000019926\"'+
        '    }'+
        '  ],'+
        '  \"publicNotes\": \"10% off better and Best\",'+
        '  \"privateNotes\": \"10% off better and Best\",'+
        '  \"eccPOSNotes\": \"10% off better and Best\"'+
        '}';
    
        return json;
    }
}