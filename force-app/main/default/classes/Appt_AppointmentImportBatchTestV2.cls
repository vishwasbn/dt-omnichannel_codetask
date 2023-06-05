@isTest
public class Appt_AppointmentImportBatchTestV2 {
  @testSetup
    static void setupData() 
    {
        List<ServiceAppointment> createData = new List<ServiceAppointment>();
        createData = Appt_TestUtil.basicAppointment_StoreConfiguration();
        //System.debug(createData);
    } 
    
    @isTest static void ImportBatchTest()
    {      
        
        Appt_Appointment_Import__c importRecord = new Appt_Appointment_Import__c();

        importRecord.Address_Line_1__c = '123 test st';
        importRecord.Appointment_Date__c = '2019-07-23';
        importRecord.Start_Time__c = '1500';
        importRecord.End_Time__c = '1514';
        importRecord.Site_ID__c = '1235';
        importRecord.Last_Name__c = 'Testy';
        importRecord.First_Name__c = 'Testerson';
        importRecord.Hybris_Customer_Vehicle_ID__c = 'WCV00000000000705079';
        importRecord.POS_Customer_Vehicle_ID__c = '91002388980000000';
        importRecord.Vehicle_Type__c = 'PAS';
        importRecord.Email_Address__c = 'test@test.com';
        importRecord.Form_Date__c = '2019-07-23';
        importRecord.Order_Date__c = '2019-07-22';
        importRecord.Form_Number__c = '1554';
        importRecord.Form_Type__c = 'WEB';
        importRecord.GUID__c = '11596';
        importRecord.Hybris_Customer_ID__c = 'W000269692';
        importRecord.Hybris_Order_ID__c = '3336661';
        importRecord.Legacy_Appointment_ID__c = '9000025185';
        importRecord.Make__c = 'HONDA';
       
        insert importRecord;
       // System.debug(importRecord);                      
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Id batchJobId = Database.executeBatch(new Appt_AppointmentImportBatchV2('1235'));
        System.debug('batchJobId' + batchJobId);
        Test.stopTest();  
        System.debug('***********END TEST***************');

        System.debug('Validate Account');
        Account validateAccount = [SELECT id, Hybris_Customer_Id__c FROM Account WHERE Hybris_Customer_Id__c = 'W000269692' LIMIT 1];
        System.debug(validateAccount);

        System.assertEquals('W000269692', validateAccount.Hybris_Customer_Id__c, 'Correct account was created');

        System.debug('Validate Appointment');
        ServiceAppointment validateAppointment = [SELECT id, Work_Order__r.AccountId, Work_Order__r.Form_Number__c,  Work_Order__r.Source__c, Work_Order__r.Order_Date__c, Date_String__c from ServiceAppointment WHERE Work_Order__r.AccountId = :validateAccount.id];
        System.debug(validateAppointment);
        System.debug(validateAppointment.Work_Order__r.Source__c);

        System.assertEquals('FILE', validateAppointment.Work_Order__r.Source__c, 'correct source was applied');
        System.assertEquals('2019-07-23', validateAppointment.Date_String__c, 'correct appointment date was set');
        System.assertEquals(Date.valueOf('2019-07-22'), validateAppointment.Work_Order__r.Order_date__c, 'Failed with Incorrect order date');
    } 
}