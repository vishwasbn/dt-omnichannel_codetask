@isTest
public class Fleet_BatchWelcomeEmailNonCreditTest {
    @isTest
    static void testWelcomeEmailNonCredit(){      
        
        list<account>acclist= new list<account>();
        List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Fleet Sales User' ];
        List<RecordType> rtList = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'B2B'];
        
        User testUser = new User (
            Username = 'wstor@ethos.com.dt.fleetdev2',
            LastName = 'Stor',
            FirstName = 'William',
            Email = 'apex+wstorr@ethos.com',
            EmailPreferencesAutoBcc = true,
            EmailPreferencesAutoBccStayInTouch = false,
            EmailPreferencesStayInTouchReminder = true,
            ProfileId = profileList[0].Id,
            Phone = '(602) 123-4567',
            Alias = 'wstr',
            CommunityNickname = 'User15960418108414009002',
            IsActive = true,
            TimeZoneSidKey = 'America/Phoenix',
            LocaleSidKey = 'en_US',            ReceivesInfoEmails = true,
            ReceivesAdminInfoEmails = true,
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            UserPreferencesActivityRemindersPopup = true,
            UserPreferencesEventRemindersCheckboxDefault = true,
            UserPreferencesTaskRemindersCheckboxDefault = true,
            UserPreferencesDisableLikeEmail = true,
            UserPreferencesSortFeedByComment = true,
            UserPreferencesShowTitleToExternalUsers = true,
            UserPreferencesHideS1BrowserUI = true,
            UserPreferencesPathAssistantCollapsed = true,
            UserPreferencesLightningExperiencePreferred = true,
            UserPreferencesHideSfxWelcomeMat = true,
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'N',
            Fleet_ECC_Key__c = '09',
            Fleet_Specialist_Assignment_Group__c = '1-50',
            Fleet_Is_Specialist__c = true
        );

        insert testUser;
        
        Account acc = new Account(
            Name='Test Account',
            Selected_State__c = 'Alaska',
            Fleet_Account_Status__c = 'Pending',
            ECC_Account_Number__c = '1234',
            Fleet_AR_App_Status__c = 'Pending',
            SAP_Created_Date__c = System.today().addDays(-1),
            Fleet_Application_Type__c = 'Non-Credit',
            Fleet_Credit_App_Status__c = 'Approved',
            Credit_Limit__c = 1300,
            Fleet_Specialist__c = testUser.Id,
            Fleet_Account_Approval_Emails_Sent__c = false,
            WelcomeEmailSent__c =false,
            RecordTypeId = rtList[0].id
            
        );
        insert acc;
         acc.Fleet_Account_Status__c = 'Customer';
         acc.Fleet_AR_App_Status__c = 'Approved';
        update acc;
       

        Contact c = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert c;
        
        //OrgWideEmailAddress Addr=new OrgWideEmailAddress(Address='abc');
        
        acc.Email__c = 'john@discountire.example';
        acc.Fleet_Primary_Contact__c = c.Id;
        acc.Lead_Email__c = 'john@discountire.example';
        update acc;

        Fleet_Email_Settings__c settings = Fleet_Email_Settings__c.getOrgDefaults();
        // Email Templates
        settings.Fleet_CashApplicationEmailName__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email';
        settings.FleetCashApplicationEmailTemplateNameAT__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email_AT';            
        settings.Fleet_CreditApplicationEmailName__c = 'Fleet_Credit_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email';
        settings.FleetCreditAppEmailTemplateName_AT__c = 'Fleet_Cash_AR_Application_and_Sales_Tax_Exemption_Certificate_s_Email_AT';
        settings.Fleet_CreditApplicationAcceptedEmail__c = 'Fleet_Credit_Application_Accepted';
        settings.Fleet_CreditApplicationAcceptedEmail_AT__c = 'Fleet_Credit_Application_Accepted_AT';
        settings.Fleet_CreditApplicationDeclinedEmail__c = 'Fleet_Credit_Application_Declined';
        settings.Fleet_CreditApplicationDeclinedEmail_AT__c = 'Fleet_Credit_Application_Declined_New_AT';
        settings.Fleet_WelcomeCashAppAcceptedEmail__c = 'Fleet_Welcome_Cash_Application_Accepted';
        settings.Fleet_WelcomeCashAppAcceptedEmail_AT__c = 'Fleet_Welcome_Cash_Application_Accepted_AT';
        settings.Fleet_WelcomeCreditAppAcceptedEmail__c = 'Fleet_Welcome_Credit_Application_Accepted';
		settings.Fleet_WelcomeCreditAppAcceptedEmail_AT__c = 'Fleet_Welcome_Credit_Application_Accepted_AT';
        settings.Fleet_ApplicationReplyToEmail__c = 'ar@discounttire.com.fleetexample';
        settings.Fleet_SenderDisplayName__c  = 'Fleet';

        //From Emails
        settings.Fleet_CreditAppAcceptFromEmail__c = 'dt_fleet@discountttire.com.testonly';
        settings.Fleet_CreditAppWelcomeFromEmail__c = 'dt_fleet@discounttire.com.example';
        settings.Fleet_CreditAppDeclinedFromEmail__c = 'gail.baker@discounttire.com.example';
        settings.Fleet_CashAppWelcomeFromEmail__c = 'dt_fleet@discounttire.com.example';
        //settings.Cash_App_Welcome_From_Email_AT__c = 'at_fleet@discounttire.com.example';
        //settings.Credit_App_Welcome_From_Email_AT__c = 'at_fleet@discounttire.com.example';
        //settings.Credit_App_Accept_From_Email_AT__c = 'at_fleet@discountttire.com.testonly';

        // BCC emails
        settings.Fleet_CreditAppAcceptBccEmails__c = 'AR@discountttire.com.fleetexample, CAP@discountttire.com.fleetexample';
        settings.Fleet_CreditAppDeclinedBccEmails__c = 'AR@discountttire.com.fleetexample';
        settings.Fleet_CreditAppWelcomeBccEmails__c = 'AR@discountttire.com.fleetexample';
        settings.Fleet_CashAppWelcomeBccEmails__c = 'AR@discountttire.com.fleetexample';
        upsert settings;
        
        Test.startTest();
        acclist.add(acc);
       
        Fleet_BatchWelcomeEmailNonCredit batchObj = new Fleet_BatchWelcomeEmailNonCredit();
        //Database.executeBatch(batchObj);
        Database.QueryLocator ql = batchObj.start(null);
        batchObj.execute(null, accList);
        batchObj.Finish(null);
        Test.stopTest();
    }
    
    @isTest
	static void testScheduler() {
        Test.startTest();
        String jobName = 'Fleet_BatchWelcomeEmailNonCredit - Daily 6AM/6PM';
        List<CronTrigger> runningJobs = [SELECT Id, State FROM CronTrigger WHERE CronJobDetail.Name = :jobName AND State IN ('WAITING')];
        if (runningJobs.size() > 0) {
            System.abortJob(runningJobs[0].Id);
        }
        System.assertEquals(0, [SELECT count() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status IN ('Queued', 'Processing') AND ApexClass.Name = 'Fleet_BatchWelcomeEmailNonCredit'], 'Existing jobs were not aborted');
        Fleet_BatchWelcomeEmailNonCredit.schedule();
        Test.stopTest();
	}

}