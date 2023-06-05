@isTest
private class Fleet_InactivityEmailTest {
    @isTest
    static void testBatchJob() {
        // Create test data
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        
        Account acc = new Account(
            Name='Test Account',
            Selected_State__c = 'Alaska',
            Fleet_Account_Status__c = 'Pending',
            ECC_Account_Number__c = '1234',
            Fleet_AR_App_Status__c = 'Pending',
            SAP_Created_Date__c = System.today().addDays(-1),
            Fleet_Application_Type__c = 'Credit',
            Fleet_Credit_App_Status__c = 'Approved',
            Credit_Limit__c = 1300,
            Fleet_Account_Approval_Emails_Sent__c = false,
            WelcomeEmailSent__c =false,
            RecordTypeId = rtList[0].id,
            Fleet_Inactivity_Notification_Enabled__c = true,
            Fleet_Last_Invoice_Date__c = Date.today().addDays(-95),
            Fleet_Inactivity_Notification_Date__c = null
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
        settings.Fleet_Inactivity_Email_AT__c = 'Fleet_Inactivity_Email_AT';
        settings.Fleet_Inactivity_Email_DT__c = 'Fleet_Inactivity_Email_DT';      
        
        settings.Fleet_Inactivity_From_Email_AT__c = 'at_fleet@americastire.com';
        settings.Fleet_Inactivity_From_Email_DT__c = 'dt_fleet@discounttire.com';  
        upsert settings;
        
        
        Test.startTest();
        // Start batch job
        Database.executeBatch(new Fleet_InactivityEmail());
        Test.stopTest();
        
        // Verify results
        acc = [SELECT Fleet_Inactivity_Notification_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(DateTime.now().addSeconds(-1), acc.Fleet_Inactivity_Notification_Date__c);
    }
    
    @isTest
    static void testBatchJobWithNoData() {
        Test.startTest();
        // Start batch job
        Database.executeBatch(new Fleet_InactivityEmail());
        Test.stopTest();
        
        // Verify no results
        Integer count = [SELECT COUNT() FROM Account WHERE Fleet_Inactivity_Notification_Date__c = TODAY];
        System.assertEquals(0, count);
    }
}