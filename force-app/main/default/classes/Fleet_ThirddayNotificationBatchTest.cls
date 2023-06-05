@isTest
private class Fleet_ThirddayNotificationBatchTest {
    @isTest
    static void testBatchJob() {
        // Create test data
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        
        Account acc = new Account(
            Name='Test Account',
            Fleet_Account_Status__c = 'Pending',
            Fleet_Pending_Additional_Info_Date__c = System.today().addDays(-3),
            Fleet_Days_Until_Decline__c = 3,
            Fleet_Application_Third_Day_Notification__c = false,
            RecordTypeId = rtList[0].id
        );
        insert acc;
        
        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert c;
        
        acc.Email__c = 'john@discountire.example';
        acc.Fleet_Primary_Contact__c = c.Id;
        acc.Lead_Email__c = 'john@discountire.example';
        update acc;
        
        Fleet_Email_Settings__c settings = Fleet_Email_Settings__c.getOrgDefaults();
        settings.Fleet_Three_Day_Notification__c = 'Fleet_Three_Day_Notification';
        settings.Fleet_Three_Day_Notification_From_Email__c = 'ar_app@discounttire.com';
        upsert settings;
        
        Test.startTest();
        // Start batch job
        Database.executeBatch(new Fleet_ThirddayNotificationBatch());
        Test.stopTest();
        
        // Verify results
        acc = [SELECT Fleet_Application_Third_Day_Notification__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, acc.Fleet_Application_Third_Day_Notification__c);

    }
    
    @isTest
    static void testScheduleJob() {
        // Schedule job
        String cronExp = '0 0 0 1 1 ?';
        String jobID = system.schedule('Test Job', cronExp, new Fleet_ThirddayNotificationBatch());
        
        // Wait for job to finish
        Test.startTest();
        List<CronTrigger> triggers = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Test Job'];
        System.assertEquals(1, triggers.size());
        String triggerId = triggers[0].Id;
        Test.stopTest();
        
    }
}