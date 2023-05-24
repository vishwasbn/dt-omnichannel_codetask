@isTest
public class Appt_NotificationCleanupBatchTest {
    @isTest 
    static void testBatch()
    {                
        Appt_TestUtil.basicAppointment_StoreConfiguration();

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_SCHEDULED;
        update sa;

        sa.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_COMPLETED;
        update sa;

        Notification__c newNotify = new Notification__c();
        newNotify.Service_Appointment__c = sa.Id;
        insert newNotify;

        Test.setCreatedDate(newNotify.Id, Datetime.now().addDays(-14));

        System.debug(newNotify);


        System.debug('***********START TEST***************');
        Test.startTest();
        Id batchId = Database.executeBatch(new Appt_NotificationCleanupBatch());           
        System.debug('batchId' + batchId);
        
        Test.stopTest();  
        System.debug('***********END TEST***************');

        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE ID =: batchId ];
        System.debug(aaj);
        System.assertEquals('Completed', aaj.Status,'Check for job to be completed');

        List<Notification__c> testNotification = [SELECT id FROM Notification__c WHERE id = :newNotify.id LIMIT 1];
        System.debug(testNotification.size());
        System.assertEquals(testNotification.size(), 0,'Check for notification to be deleted');
    }


}