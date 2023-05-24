global class Fleet_BatchWelcomeEmailNonCredit implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    public integer recordcount=0;
    public static String lprefix = 'LOG_ATH:';
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        Date startDate = System.today();
        Date endDate = startDate.addDays(-1*Integer.valueOf(Label.Fleet_WelcomeEmailNumberOfDays));
        return Database.getQueryLocator([SELECT Id, RecordTypeId, Fleet_AR_App_Status__c, SAP_Created_Date__c, Welcome_Email_Triggered__c, ECC_Account_Number__c,WelcomeEmailSent__c, Fleet_Application_Type__c,Selected_State__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name, Fleet_Business_Located__c, AT_Customer__c FROM Account WHERE Fleet_Account_Status__c = 'Customer' and ECC_Account_Number__c != null and Fleet_AR_App_Status__c = 'Approved' and RecordType.Name = 'B2B' and Fleet_Primary_Contact__c != null and SAP_Created_Date__c >= :endDate and SAP_Created_Date__c < :startDate and Fleet_Application_Type__c = 'Non-Credit' and WelcomeEmailSent__c = false and (NOT Name like '%GERBER COLL%') and (NOT Name like '%CLASSIC COLL%') and (NOT Name like '%CALIBER COLL%') and (NOT Name like '%SERVICE KING%')]);
        
    }
    
    public void execute(Database.BatchableContext bc,List<Account> batch){
        recordcount=recordcount+batch.size();
        
        String APPLICATION_STATUS = 'Approved';
        // Set up email util
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        
        String fromAddress = emailSettings.Fleet_CashAppWelcomeFromEmail__c;
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c);
        
        Set<Id> accountEmailSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        for(Account acc : batch){
            
            //---Confirm logic for when Fleet_Primary_Contact Community User should be created 
            if (acc.ECC_Account_Number__c != null &&                 
                acc.Fleet_Application_Type__c == 'Non-Credit' && 
                acc.RecordTypeId == b2bRT &&
                !acc.WelcomeEmailSent__c &&
                acc.Fleet_AR_App_Status__c == APPLICATION_STATUS && 
                acc.SAP_Created_Date__c >= System.today().addDays(-1*Integer.valueOf(Label.Fleet_WelcomeEmailNumberOfDays))
               ) {
                   
                   acc.Welcome_Email_Triggered__c = false;
                   
                   // Send non-credit application email
                   Fleet_AccountEmailUtil.sendNonCreditAppAcceptedWelcomeEmail(emailSettings, acc.id, acc, owaList, templateId);
                   
                   accountEmailSet.add(acc.id);
                   
                   
                   // Set list of community users to be created
                   if(acc.Fleet_Primary_Contact__c != null){
                       contactIdSet.add(acc.Fleet_Primary_Contact__c);
                       accountIdSet.add(acc.Id);
                   }
                   
               }
        }
        
        if(!Test.isRunningTest() && accountEmailSet.size() > 0){
            Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(accountEmailSet);
        }
        
        // Checks setting to determine if it should create users, if not it will return and the users wont be created
        if (!Fleet_SettingUtil.getSettingBooleanValue(Fleet_Values.SETTING_FLEET_AUTO_CREATE_COMMUNITY_USERS))
        {
            System.debug(lprefix + Fleet_Values.SETTING_FLEET_AUTO_CREATE_COMMUNITY_USERS + ' is not set, not automatically creating Community Users');
            return;
        }
        
        //---Convert Contacts to Community Users
        if (contactIdSet.size() > 0) {
            System.debug( lprefix + 'Contacts to convert:' + contactIdSet);
            if(!Test.isRunningTest()){
            	Fleet_CommunityUserBuilder.convertContactToCommunityUser(contactIdSet);
            }    
        }
    }
    
    global void finish(Database.BatchableContext bc){
        system.debug('record processed'+recordcount);  
    }
    
    global void execute(SchedulableContext sc) {
        Fleet_BatchWelcomeEmailNonCredit batch = new Fleet_BatchWelcomeEmailNonCredit(); 
        database.executebatch(batch, 1);
    }
    
    public static String schedule() {
        String schedule = '0 0 6,18 ? * *';
        Fleet_BatchWelcomeEmailNonCredit batch = new Fleet_BatchWelcomeEmailNonCredit(); 
        return System.schedule('Fleet_BatchWelcomeEmailNonCredit - Daily 6AM/6PM', schedule, batch);
    }
}