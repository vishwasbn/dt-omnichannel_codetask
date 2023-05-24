@isTest (seeAllData = false)
private class Fleet_ApplicationControllerTest {
    public static String APPLICATION_TYPE_CREDIT = 'Credit';
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
    }

    static testMethod void testGetByGuid() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        update acc;

        String appGuid = 'x';

        Fleet_Application__c app = new Fleet_Application__c();
        app.Parent_Account__c = acc.Id;
        app.Application_GUID__c = appGuid;
        insert app;

        Test.startTest();
        Fleet_Application__c testApp = Fleet_ApplicationController.retrieveFleetAppByGUID(appGuid);
        System.assertEquals(testApp.id, app.id);
        Test.stopTest();
    }

    static testMethod void testSaveOrSubmit() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        update acc;

        String appGuid = 'x';

        Fleet_Application__c app = new Fleet_Application__c();
        app.Parent_Account__c = acc.Id;
        app.Application_GUID__c = appGuid;
        insert app;

        //---Setup Parameters
        Map<String, Object> fA = new Map<String, Object>();
        fA.put('Id', app.Id);
        fA.put('Company_Full_Legal_Name__c', 'Test Company');
        fA.put('Number_Of_Fleet_Vehicles__c', 10);
        fA.put('Years_In_Business__c', 3);

        String appStatus = 'Submitted';

        Test.startTest();
        String returnVal = Fleet_ApplicationController.saveOrSubmitFleetApplication(fA, appStatus);
        System.assertEquals(returnVal, 'success');
        Test.stopTest();
    }

    static testMethod void testAddingAttachments() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        update acc;

        String appGuid = 'x';

        Fleet_Application__c app = new Fleet_Application__c();
        app.Parent_Account__c = acc.Id;
        app.Application_GUID__c = appGuid;
        insert app;

        //---Setup Parameters
        Map<String, Object> fileMap = new Map<String, Object>();
        fileMap.put('attachmentType', 'Credit Application');
        fileMap.put('fileName', 'test.csv');
        fileMap.put('fileContent', 'xxx');

        List<Map<String, Object>> fileList = new List<Map<String, Object>>();
        fileList.add(fileMap);

        Test.startTest();
        String returnVal = Fleet_ApplicationController.insertFleetAppAttachments(acc.Id, app.Id, fileList);
        System.assertEquals(returnVal, 'success');
        Test.stopTest();
    }

    static testMethod void testRemoveFile() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        update acc;

        String appGuid = 'x';

        Fleet_Application__c app = new Fleet_Application__c();
        app.Parent_Account__c = acc.Id;
        app.Application_GUID__c = appGuid;
        insert app;

        Test.startTest();
        String returnVal = Fleet_ApplicationController.removeFile(acc.Id, 'Credit Application');
        System.assertEquals(returnVal, 'success');
        Test.stopTest();
    }

    static testMethod void testInsertCreditAppRef() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        acc.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        update acc;

        String appGuid = 'x';

        Fleet_Application__c app = new Fleet_Application__c();
        app.Parent_Account__c = acc.Id;
        app.Application_GUID__c = appGuid;
        insert app;

        List<Fleet_App_Credit_Reference__c> crList = new List<Fleet_App_Credit_Reference__c>();
        Fleet_App_Credit_Reference__c cr = new Fleet_App_Credit_Reference__c();

        Test.startTest();
        String returnVal = Fleet_ApplicationController.insertCreditAppReferences(acc.Id, crList);
        System.assertEquals(returnVal, 'success');
        Test.stopTest();
    }
}