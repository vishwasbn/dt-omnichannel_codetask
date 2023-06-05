@IsTest
public with sharing class Appt_CapUpHistSchTest {
    
    @isTest 
    static void testScheduler () {
        // CRON expression: midnight on March 15. Because this is a test, 
        // job is supposed to execute immediately after Test.stopTest()
        //String cronExpr = '0 0 0 15 3 ? 2022';
    
        // NB: test data not needed, because we're not testing Apex Batch results
        // That will be tested somewhere else
    
        // Verify that AsyncApexJob is empty
        // not strictly necessary but makes what is going on later clearer
        //List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        //System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
    
        Test.startTest();
        // Schedule the test job
        //String jobId = System.schedule('myJobTestJobName', cronExpr, new Appt_CapacityUpdateHistorySchedulable());
        Appt_CapacityUpdateHistorySchedulable.setupschedule();
        Test.stopTest();
    
        // There will now be two things in AsyncApexJob - the Schedulable itself
        // and also the Batch Apex job. This code looks for both of them
    
        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('Appt_CapacityUpdateHistorySchedulable', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    
        // check apex batch is in the job list
        List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
        System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
        System.assertEquals('Appt_CapacityUpdateHistoryBatch', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
    
    
    }
}