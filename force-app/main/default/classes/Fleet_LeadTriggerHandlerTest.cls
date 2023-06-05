@isTest (seeAllData = false)
private class Fleet_LeadTriggerHandlerTest {

    @TestSetup
    static void createTestClassData() {
        User testUser1 = new User();
        testUser1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Fleet Sales User'].Id;
        testUser1.FirstName = 'firstName';
        testUser1.LastName = 'lastName';
        testUser1.Email = 'test1@test.com';
        testUser1.Username = 'test1@test.com' + System.currentTimeMillis();
        testUser1.CompanyName = 'TEST';
        testUser1.Title = 'title';
        testUser1.Alias = 'ali11';
        testUser1.TimeZoneSidKey = 'America/Los_Angeles';
        testUser1.EmailEncodingKey = 'UTF-8';
        testUser1.LanguageLocaleKey = 'en_US';
        testUser1.LocaleSidKey = 'en_US';
        testUser1.Fleet_Is_Specialist__c=true;

        insert testUser1;

        User testUser2 = new User();
        testUser2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Fleet Sales User'].Id;
        testUser2.FirstName = 'firstName22';
        testUser2.LastName = 'lastName22';
        testUser2.Email = 'test2@test.com';
        testUser2.Username = 'test2@test.com' + System.currentTimeMillis();
        testUser2.CompanyName = 'TEST22';
        testUser2.Title = 'title22';
        testUser2.Alias = 'ali22';
        testUser2.TimeZoneSidKey = 'America/Los_Angeles';
        testUser2.EmailEncodingKey = 'UTF-8';
        testUser2.LanguageLocaleKey = 'en_US';
        testUser2.LocaleSidKey = 'en_US';
        testUser2.Fleet_Is_Specialist__c=true;

        insert testUser2;

        Id b2bRT = Schema.Sobjecttype.Lead.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        Lead testLead1 = new Lead(LastName='TestLead111', Company='TestLead111 ribs', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'testlead@ethos.com',
            Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website');
            testLead1.Fleet_Number_of_Vehicles__c = 34;
            testLead1.OwnerId = testUser1.Id;
            testLead1.RecordTypeId = b2bRT;
            testLead1.Fleet_Public_Notes__c = 'test';
        	testLead1.State__c = 'new';
        insert testLead1;

        Lead testLead2 = new Lead(LastName='TestLead222', Company='TestLead222 ribs', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'testlead2@ethos.com',
            Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website');
            testLead2.Fleet_Number_of_Vehicles__c = 33;
            testLead2.OwnerId = testUser1.Id;
            testLead2.RecordTypeId = b2bRT;
            testLead2.Fleet_Public_Notes__c = 'test';
        	testLead2.State__c = 'new';
        insert testLead2;
        
    }
    
    static testMethod void testTriggerHandler() {
        system.debug('testTriggerHandler() ENTRY -----------');

        User firstUser = [SELECT Id FROM User WHERE Alias = 'ali11'];
        system.debug('   firstUser='+firstUser);
        User secondUser = [SELECT Id FROM User WHERE Alias = 'ali22'];
        system.debug('   secondUser='+secondUser);
        Lead testLead = [SELECT Id, OwnerId, Assigned_Date__c, Fleet_Specialist__c FROM lead WHERE LastName='TestLead111'];
        system.debug('   testLead='+testLead);
        Lead unchangedLead = [SELECT Id, OwnerId, Assigned_Date__c, Fleet_Specialist__c FROM lead WHERE LastName='TestLead222'];
        system.debug('   unchangedLead='+unchangedLead);

        Test.startTest();

        System.assertEquals(firstUser.Id, testLead.OwnerId, 'Expected first testLead.ownerId to be from first test user');
        System.assert(testLead.Assigned_Date__c == null, 'Expected testLead.Assigned_Date__c to be null');
        System.assertEquals(firstUser.Id, unchangedLead.OwnerId, 'Expected first unchangedLead.ownerId to be from first test user');
        
        
        
        testLead.OwnerId = secondUser.Id;
        update testLead;


        Lead testLeadRequeried = [SELECT Id, OwnerId, Assigned_Date__c, Fleet_Specialist__c FROM lead WHERE LastName='TestLead111'];
        system.debug('   testLeadRequeried='+testLeadRequeried);
        Lead unchangedLeadRequeried = [SELECT Id, OwnerId, Assigned_Date__c, Fleet_Specialist__c FROM lead WHERE LastName='TestLead222'];
        system.debug('   unchangedLeadRequeried='+unchangedLeadRequeried);

        Test.stopTest();


        system.debug('testTriggerHandler() EXIT ---');

    }
}