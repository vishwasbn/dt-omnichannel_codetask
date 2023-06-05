@isTest
public class Appt_NotificationCleanupSchedulerTest {

    @isTest 
    static void Appt_NotificationCleanupBatchTest()
    {                

        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_NotificationCleanupBatchScheduler.setupSchedule();        
        
        Test.stopTest(); 
        System.debug('***********END TEST***************');    
        
        CronTrigger ct =  [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1];
        System.debug(ct.CronJobDetail.Name);
        System.assert(ct.CronJobDetail.Name.contains('NotificationCleanupBatchSchedule'),'check for job to be created');
    }

    
}