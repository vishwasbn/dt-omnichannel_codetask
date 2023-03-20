@isTest
public class StateCityController_Test {
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

        Id b2bRT = Schema.Sobjecttype.Lead.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        Lead testLead1 = new Lead(LastName='TestLead111', Company='TestLead111 ribs', Fleet_Prefer_Purchase__c='Purchase Order', Email = 'testlead@ethos.com',
                                  Fleet_Years_Business__c=4, Fleet_Purchase_Product__c='Resale', Fleet_Business_Located__c='Arizona', Fleet_How_Hear__c='Website');
        testLead1.Fleet_Number_of_Vehicles__c = 34;
        testLead1.OwnerId = testUser1.Id;
        testLead1.RecordTypeId = b2bRT;
        testLead1.Fleet_Public_Notes__c = 'test';
        insert testLead1;
        
    }
     static testMethod void testMethod1() {
         User testUser1 =[SELECT Id,FirstName,LastName,Email,Username,
                          CompanyName,Title,Alias,TimeZoneSidKey,EmailEncodingKey,LanguageLocaleKey,LocaleSidKey,Fleet_Is_Specialist__c FROM User LIMIT 1]; 
         state__c objState = New state__c();
         objState.Name = 'Test';
         Insert objState;
         City__c objCity = New City__c();
         objCity.Name = 'Test';
         objCity.State__c = objState.Id;
         Insert objCity;
         ApexPages.StandardController stdController = new ApexPages.StandardController(testUser1);
        stateCityController controller = new stateCityController(stdController);
         controller.Selectedstate= 'Test';
         controller.Selectedcity= 'ALL';
         controller.getState();
         controller.getCities();
         stateCityController.getCitiesOptions('Test');
         stateCityController.saveStateCity('Alabama',New List<string>{'ALL'},testUser1.Id);
         stateCityController.saveStateCity('',New List<string>{''},testUser1.Id);
     }
}