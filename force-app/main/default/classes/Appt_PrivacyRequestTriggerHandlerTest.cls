@isTest
public class Appt_PrivacyRequestTriggerHandlerTest {
   
    @isTest static void Appt_PrivacyRequestTriggerHandlerTest()
    {               


        RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE Name = 'Person Account' and SObjectType = 'Account'];
        Account testAccount = new Account();

        // for person accounts we can not update the Name field instead we have to update the    FirstName and LastName individually

        testAccount.FirstName = 'Fred';
        testAccount.LastName = 'Smith';
        testAccount.RecordType = personAccountRecordType;
        insert testAccount;

        Asset testAsset = new Asset();
        testAsset.AccountId = testAccount.id;
        testAsset.Vehicle_Manufacture_Year__c = '2021';
        testAsset.Vehicle_Class__c = 'VAN';
        testAsset.Name = 'test Asset';

        insert testAsset;


        Privacy_Request__c newPrivacyRequest =  new Privacy_Request__c();

        newPrivacyRequest.Account__c = testAccount.id;
        newPrivacyRequest.Confirmed__c = true;


        System.debug('***********START TEST***************');
        Test.startTest();
        
        insert newPrivacyRequest;
        
        Test.stopTest();  
        System.debug('***********END TEST***************');
        System.debug(newPrivacyRequest);

        Asset testVehicle = [SELECT id, Vehicle_Manufacture_Year__c, Vehicle_Class__c FROM Asset WHERE id = :testAsset.id];
        System.debug('response vehicle');
        System.debug(testVehicle);

        Account testAccountValidation = [SELECT id, FirstName FROM Account WHERE id = :testAccount.id];
        System.debug('response Account');
        System.debug(testAccountValidation);

        System.assertNotEquals('Fred', testAccountValidation.FirstName, 'Check for first name to be scrambled');
        System.assertNotEquals('VAN', testVehicle.Vehicle_Class__c, 'Check for vehcile info to be scrambled');
       
   
    } 
}