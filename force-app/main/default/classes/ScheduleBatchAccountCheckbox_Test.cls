@isTest
private class ScheduleBatchAccountCheckbox_Test{
    
    // CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2042';
    
    static testmethod void testScheduledJob() {
        Id recordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        Account a = new Account(Name = 'Test Account', RecordTypeId=recordTypeId);
        insert a;
        Case c1 = new Case(Subject = 'Test Case 1', AccountId = a.id);
        insert c1;
        Case c2 = new Case(Subject = 'Test Case 2', AccountId = a.id);
        insert c2;
        Test.startTest();                
        
        // Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest',
                                       CRON_EXP, 
                                       new ScheduleBatchUpdateAccountCaseCheckbox());
        
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
        List<Account> accounts = [SELECT id From Account where Has_Multiple_Cases__c = true]; 
        System.assertEquals(0, accounts.size(), 'Should have 0 accounts with multiple cases');
        Test.stopTest();                       
    }
    
    static testMethod void testBatchJob() {
        Id recordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();

        Account a = new Account(Name = 'Test Account', RecordTypeId=recordTypeId);
        insert a;
        Case c1 = new Case(Subject = 'Test Case 1', AccountId = a.id);
        insert c1;
        Case c2 = new Case(Subject = 'Test Case 2', AccountId = a.id);
        insert c2;
        Test.startTest();
        BatchUpdateAccountMultipleCaseCheckbox b = new BatchUpdateAccountMultipleCaseCheckbox();
        database.executebatch(b);
        Test.stopTest();
        
        // Check accounts
        List<account> accounts = [SELECT id From Account where Has_Multiple_Cases__c = true];
        System.assertEquals(1, accounts.size(), 'Should have 1 account with multiple cases'); 
    }
}