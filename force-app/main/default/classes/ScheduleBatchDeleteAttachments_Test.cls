@isTest
private class ScheduleBatchDeleteAttachments_Test {
    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2042';
    
    static testmethod void testScheduledJob() {
        Case c = new Case(Subject = 'Test Case');
        insert c;
        EmailMessage e = new EmailMessage(ParentId = c.id, Incoming = false);
        insert e;
        Attachment a = new Attachment(ParentId = e.id, Name = 'Test Attachment', Body = Blob.valueOf('hello'));
        insert a;
        Test.startTest();                
        
        // Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest',
                                       CRON_EXP, 
                                       new ScheduleBatchDeleteOutgoingAttachments());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2042-03-15 00:00:00', String.valueOf(ct.NextFireTime));  
        
        // Verify the scheduled job hasn't run yet.
        EmailMessage email = [SELECT id, (select id from Attachments) From EmailMessage limit 1]; 
        System.assertEquals(1, email.Attachments.size(), 'Should have 1 attachment');
        Test.stopTest();                       
    }
    
    static testMethod void testBatchJob() {
        Case c = new Case(Subject = 'Test Case');
        insert c;
        EmailMessage e = new EmailMessage(ParentId = c.id, Incoming = false);
        insert e;
        Attachment a = new Attachment(ParentId = e.id, Name = 'Test Attachment', Body = Blob.valueOf('hello'));
        insert a;
        Test.startTest();
        BatchDeleteOutgoingEmailAttachments b = new BatchDeleteOutgoingEmailAttachments();
        database.executebatch(b);
        Test.stopTest();
        
        // Check attachments
        EmailMessage email = [SELECT id, (select id from Attachments) From EmailMessage limit 1]; 
        System.assertEquals(0, email.Attachments.size(), 'Should have 0 attachments');
    }
}