@isTest
public with sharing class Appt_NotifDelayedSchedulerTest {
    @isTest 
    static void testScheduler()
    {                

        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_NotificationDelayedScheduler.setupSchedule();        
        
        Test.stopTest(); 
        System.debug('***********END TEST***************');    
        
        CronTrigger ct =  [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1];
        System.debug(ct.CronJobDetail.Name);
        System.assert(ct.CronJobDetail.Name.contains('Appt_NotificationDelayedSendBatchTest'),'check for job to be created');
    }
}