@isTest(SeeAllData=false)
public class Appt_BatchApexErrorTriggerTest 
{
    @isTest static void createBatchError()
    {
        Test.startTest();

        BatchApexErrorEvent batEvnt = new BatchApexErrorEvent();

        batEvnt.Message = 'Unit Test Message';
        Database.insertImmediate( batEvnt );

        Test.getEventBus().deliver();
        Test.stopTest();
        Test.getEventBus().deliver(); 

        System.assertEquals(1, [SELECT Id FROM appt_BatchProcessError__c].size());        
    }
}