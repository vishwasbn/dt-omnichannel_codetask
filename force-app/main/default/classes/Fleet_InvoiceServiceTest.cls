@IsTest
public class Fleet_InvoiceServiceTest {

    @testSetup static void createTestClassData() {
        Account acc = new Account(
            Name='Test Account',
            Fleet_Account_Status__c='Prospect'
        );
        insert acc;

        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert c;
        
        acc.Fleet_Primary_Contact__c = c.Id;
        update acc;

        Id siteRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();

        Account site = new Account( Name='1958',SAP_Store_ID__c='1958', Store_ID__c='1958', RecordTypeId =siteRT);
        insert site;
    }

    static testMethod void testBuildCARHttpReq() {
        Test.startTest();
        Fleet_InvoiceService.isTest = true;
        HttpRequest json = Fleet_InvoiceService.buildCARHttpReq('');
        Test.stopTest();
    }
    
    static testMethod void testCallDetail() {
        Test.startTest();
        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testCallDetail();
        Fleet_InvoiceService.testCallSearch();
        Fleet_InvoiceService.testCallSummary();
        Test.stopTest();
    }
	
    static testMethod void testGetSummary() {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.ECC_Account_Number__c = '29894';
        update acc;

        Date startDate = Date.newInstance(2000, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);

        String invoiceIdSearch = '';
        String vinNumSearch = '12';
        String poNumSearch = 'No';

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarSummaryModelTest.getJSON();

        Test.startTest();
        String json = Fleet_InvoiceController.getInvoiceSummaryDataForDisplay(acc.Id, startDate, endDate, invoiceIdSearch,vinNumSearch,poNumSearch);
        Test.stopTest();
    }

    static testMethod void testGetDetail() {

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarDetailModelTest.getJSON();
       
        String siteId = '1958';
        String invoiceId = '123';
        String invoiceBusinessDate = '01/01/2020';

        Test.startTest();
        String json = Fleet_InvoiceController.getInvoiceDetail( siteId, invoiceId, invoiceBusinessDate);
        Test.stopTest();
    }

    static testMethod void testGetMisc() {

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarDetailModelTest.getJSON();

        String siteId = '1958';

        Test.startTest();
        String siteData = Fleet_InvoiceController.getSiteData(siteId);
        String mockData = Fleet_InvoiceController.getMockInvoiceDetail();
        Test.stopTest();
    }
    static testMethod void testPoNumberSearch() {

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.ECC_Account_Number__c = '29894';
        update acc;

        Date startDate = Date.newInstance(2000, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);

        String invoiceIdSearch = '';
        String vinNumSearch = '';
        String poNumSearch = 'No';

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarSummaryModelTest.getJSON();

        Test.startTest();
        String json = Fleet_InvoiceController.getInvoiceSummaryDataForDisplay(acc.Id, startDate, endDate, invoiceIdSearch,vinNumSearch,poNumSearch);
        Test.stopTest();
    }
    static testMethod void testInvoiceIdSearch() {

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.ECC_Account_Number__c = '29894';
        update acc;

        Date startDate = Date.newInstance(2000, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);

        String invoiceIdSearch = '1006048';
        String vinNumSearch = '';
        String poNumSearch = '';

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarSummaryModelTest.getJSON();

        Test.startTest();
        String json = Fleet_InvoiceController.getInvoiceSummaryDataForDisplay(acc.Id, startDate, endDate, invoiceIdSearch,vinNumSearch,poNumSearch);
        Test.stopTest();
    }
    static testMethod void testInvoiceAndPoSearch() {

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.ECC_Account_Number__c = '29894';
        update acc;

        Date startDate = Date.newInstance(2000, 4, 24);
        Date endDate = Date.newInstance(2020, 10, 24);

        String invoiceIdSearch = '1006048';
        String vinNumSearch = '';
        String poNumSearch = 'No';

        Fleet_InvoiceService.isTest = true;
        Fleet_InvoiceService.testPayload = Fleet_CarSummaryModelTest.getJSON();

        Test.startTest();
        String json = Fleet_InvoiceController.getInvoiceSummaryDataForDisplay(acc.Id, startDate, endDate, invoiceIdSearch,vinNumSearch,poNumSearch);
        Test.stopTest();
    }
    
}