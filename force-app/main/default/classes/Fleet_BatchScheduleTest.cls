//SF is forcing me to use seeAllData = true because of error - ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
// However this test class still only tests test data created within the test class
@isTest (seeAllData = true)
private class Fleet_BatchScheduleTest {

    public static final String ACCOUNT_STATUS_PROSPECT = 'Prospect';
    public static String CRON_EXP = '0 0 15 15 03 ? 2022';
    
    static void createTestClassData() {


        User specialist1 = getNewUser('Super1', 'Specialist', 'Fleet Sales User');

        Account acc = new Account(
            Name='Test Account batch test 802 730',
            Fleet_Specialist__c = specialist1.Id,
            Fleet_Account_Status__c = ACCOUNT_STATUS_PROSPECT
        );
        insert acc;

        Account acc2 = new Account(
            Name='Test Account batch test 855 855',
            Fleet_Specialist__c = specialist1.Id,
            Fleet_Account_Status__c = 'Customer',
            ECC_Account_Number__c = '990999'
        );
        insert acc2;

        Id b2BContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();

        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example.test.855test',
            AccountId = acc.Id,
            Convert_To_Fleet_Community_Manager__c = true,
            RecordTypeId = b2BContactRT
        );
        insert c;

        Contact c2 = new Contact(
            FirstName='Jonny',
            LastName='Johnsonson',
            Email='john@discountire.example.test.855855855test',
            AccountId = acc2.Id,
            Convert_To_Fleet_Community_Manager__c = true,
            RecordTypeId = b2BContactRT
        );
        insert c2;
        
        acc.Fleet_Primary_Contact__c = c.Id;
        update acc;

        Id b2bRT = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();

        List<String> oppStagesList = getOppStages();
        String firstOppStage = (oppStagesList.size() > 0) ? oppStagesList[0] : '2. Qualify the Target';

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            Fleet_Primary_Contact__c = c.Id,
            AccountId=acc.Id,
            CloseDate=System.Today(),
            StageName=firstOppStage,
            Customer_Type__c = 'Fleet',
            RecordTypeId = b2bRT,
            Fleet_Reg_Corp_Location__c='Alabama',
            State__c='Alabama'
        );
        insert opp;


        Fleet_Application__c app = new Fleet_Application__c();
        app.isApplicationSubmitted__c = true;
        app.Parent_Account__c = acc.Id;
        app.Billing_Address2__c='test address';
        insert app;
        
      
    }

    public static User getNewUser(String firstName, String lastName, String profileName)
    {
        User newUser = new User();
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        newUser.FirstName = firstName;
        newUser.LastName = lastName;
        newUser.Email = 'test@discounttire.com';
        newUser.Username = 'test@discounttire.com' + System.currentTimeMillis();
        newUser.CompanyName = 'TEST';
        newUser.Title = 'title';
        newUser.Alias = 'alias';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
  
        insert newUser;
        return newUser;
    }

    public static List<String> getOppStages(){
        List<String> pickListValuesList= new List<String>();
         Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry pickListVal : ple){
             pickListValuesList.add(pickListVal.getLabel());
         }     
         return pickListValuesList;
     }
    
    /*
    static testmethod void testFleet_BatchShedule() {
        
        Test.startTest();
        Id b2BContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        Id b2bRT = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        
        Account newAcct = new Account();
        newAcct.Name='Test Account batch test 802 730';
        newAcct.Fleet_Customer_Type__c = 'Fleet';
        newAcct.Fleet_Application_Type__c = 'Credit';
        newAcct.Fleet_AR_Notification_Comments__c = 'testing text area';
        insert newAcct;
        
        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example.test.855test',
            AccountId = newAcct.Id,
            Convert_To_Fleet_Community_Manager__c = true,
            RecordTypeId = b2BContactRT
        );
        insert c;
        
         Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            Fleet_Primary_Contact__c = c.Id,
            AccountId=newAcct.Id,
            CloseDate=System.Today(),
            StageName='Suspect - 0%',
            Customer_Type__c = 'Fleet',
            RecordTypeId = b2bRT
        );
        insert opp;
        
        system.debug('@@@ cron: '+ Fleet_IntegrationUtil.getSettingValue( Fleet_Values.BATCH_SCHEDULE_CRONEXP_LIST));      
        String jobId = System.schedule('testBasicScheduledApex',CRON_EXP, new Fleet_BatchSchedule());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
              
        Test.stopTest();
    }
    */
    
    static testMethod void testProcessApplication() {
        Test.startTest();
        User specialist1 = getNewUser('Super1', 'Specialist', 'Fleet Sales User');
        Account acc2 = new Account(
            Name='Test Account batch test 855 855',
            Fleet_Specialist__c = specialist1.Id,
            Fleet_Account_Status__c = 'Customer',
            ECC_Account_Number__c = '099999'
        );
        insert acc2;
        
        Fleet_Application__c app = new Fleet_Application__c();
        app.isApplicationSubmitted__c = true;
        app.Parent_Account__c = acc2.Id;
        app.Billing_Address2__c ='test add';
        insert app;
        
        Fleet_BatchSchedule.setupSchedule();
        Fleet_BatchSchedule.process();
        
        Test.stopTest();
    }
    static testMethod void testProcessApplication1() {
        Test.startTest();
        User specialist1 = getNewUser('Super1', 'Specialist', 'Fleet Sales User');
        Account acc2 = new Account(
            Name='Test Account batch test 855 855',
            Fleet_Specialist__c = specialist1.Id,
            Fleet_Account_Status__c = 'Customer',
            ECC_Account_Number__c = '099999'
        );
        insert acc2;
        
        Fleet_Application__c app = new Fleet_Application__c();
        app.isApplicationSubmitted__c = true;
        app.Parent_Account__c = acc2.Id;        
        insert app;
        
        
        Fleet_BatchSchedule.processApplications();
        
        Test.stopTest();
    }
    
    static testMethod void testprocessCTC() {
        Id b2BContactRT = Schema.Sobjecttype.Contact.getRecordTypeInfosByDeveloperName().get(Fleet_Values.CONTACT_RECORD_TYPE_B2B_CONTACT).getRecordTypeId();
        
        Account newAcct = new Account();
        newAcct.Name='Test Account batch test 802 730';
        newAcct.Fleet_Customer_Type__c = 'Fleet';
        newAcct.Fleet_Application_Type__c = 'Credit';
        newAcct.Fleet_Account_Status__c = 'Customer';
        newAcct.Fleet_AR_Notification_Comments__c = 'testing text area';
        newAcct.ECC_Account_Number__c = 'skmafHOPwermkdeHYMHD';
        insert newAcct;
        
        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example.test.855test',
            AccountId = newAcct.Id,
            Convert_To_Fleet_Community_Manager__c = true,
            Is_Fleet_Community_Manager__c = false,
            RecordTypeId = b2BContactRT
        );
        insert c;
        
        Fleet_BatchSchedule.processContactstoConvert();
    }
    
    static testMethod void testGetByGuid() {
        createTestClassData();
    
        Fleet_BatchSchedule.isTest = true;

        Test.startTest();
        //Fleet_BatchSchedule.setupSchedule();
        //Fleet_BatchSchedule.process();

        List<Account> accnts = [SELECT Id,Fleet_Customer_Type__c FROM Account WHERE Name='Test Account batch test 802 730'];
        Account acct = accnts.get(0);
        //System.assertEquals(acct.Fleet_Customer_Type__c, 'Fleet');

        List<Contact> cnts = [SELECT Id,Convert_To_Fleet_Community_Manager__c, Is_Fleet_Community_Manager__c FROM Contact WHERE Email='john@discountire.example.test.855855855test'];
        Contact cnt = cnts.get(0);
        //System.assertEquals(cnt.Is_Fleet_Community_Manager__c, true);
       // System.assertEquals(cnt.Convert_To_Fleet_Community_Manager__c, false);
        Fleet_BatchSchedule.purgeAllRecords(10);
        Fleet_BatchSchedule.processOpportunity();
        //Fleet_BatchSchedule.processContactstoConvert();
        Fleet_BatchSchedule.processIntMessagePurge();
        Boolean value = Fleet_BatchSchedule.areLimitsOk();
        System.assertEquals(true, value);
        Boolean value1 = Fleet_BatchSchedule.checkLimit('limitName', 4, 8);
        System.assertEquals(false, value1);
        Boolean value2 = Fleet_BatchSchedule.checkLimit('limitName', 8, 5);
        System.assertEquals(true, value2);
        Test.stopTest();
    }
    
}