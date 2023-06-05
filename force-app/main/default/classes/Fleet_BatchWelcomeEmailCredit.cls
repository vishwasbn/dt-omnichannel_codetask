global class Fleet_BatchWelcomeEmailCredit implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    public integer recordcount=0;
    public static String lprefix = 'LOG_ATH:';
    
    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //List<Account> accountsToCheck = new List<Account>();
        //accountsToCheck = 'SELECT Id, SAP_Created_Date__c, Fleet_AR_App_Status__c, Fleet_Credit_App_Status__c, Fleet_Account_Approval_Emails_Sent__c, ECC_Account_Number__c, WelcomeEmailSent__c, Selected_State__c, FLEET_MANAGER_SALES__c, RecordTypeId,Fleet_Application_Type__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name, Fleet_Business_Located__c, ShippingPostalCode, Credit_Limit__c, Fleet_Account_Status__c FROM Account WHERE Fleet_Account_Status__c = 'Customer' and ECC_Account_Number__c != null and Fleet_AR_App_Status__c = 'Approved' and RecordType.Name = 'B2B' and SAP_Created_Date__c >= LAST_N_DAYS:21 and SAP_Created_Date__c < LAST_N_DAYS:0 and Fleet_Application_Type__c = 'Credit' and Fleet_Credit_App_Status__c = 'Approved' and Credit_Limit__c >= 0 and WelcomeEmailSent__c = false';
		Date startDate = System.today();
        Date endDate = startDate.addDays(-1*Integer.valueOf(Label.Fleet_WelcomeEmailNumberOfDays));
        return Database.getQueryLocator([SELECT Id, AT_Customer__c, Welcome_Email_Triggered__c, SAP_Created_Date__c, 
                                         Fleet_AR_App_Status__c, Fleet_Credit_App_Status__c, Fleet_Account_Approval_Emails_Sent__c, 
                                         ECC_Account_Number__c, WelcomeEmailSent__c, Selected_State__c, FLEET_MANAGER_SALES__c, 
                                         RecordTypeId,Fleet_Application_Type__c, Fleet_Primary_Contact__c, 
                                         Fleet_Primary_Contact__r.Email, Name, Fleet_Business_Located__c, ShippingPostalCode, 
                                         Credit_Limit__c, Fleet_Account_Status__c FROM Account WHERE 
                                         Fleet_Account_Status__c = 'Customer' and ECC_Account_Number__c != null and 
                                         Fleet_AR_App_Status__c = 'Approved' and RecordType.Name = 'B2B' and 
                                         SAP_Created_Date__c >= :endDate and SAP_Created_Date__c < :startDate and 
                                         Fleet_Application_Type__c = 'Credit' and Fleet_Credit_App_Status__c = 'Approved' and 
                                         Credit_Limit__c >= 0 and WelcomeEmailSent__c = false and (NOT Name like '%GERBER COLL%') and 
                                         (NOT Name like '%CLASSIC COLL%') and (NOT Name like '%CALIBER COLL%') and 
                                         (NOT Name like '%SERVICE KING%')]);
        
    }
    
    // Execute method
    
    global void execute(Database.BatchableContext BC, List<Account> accountsToCheck ) {
        recordcount=recordcount+accountstocheck.size();
        
        //public static String lprefix = 'LOG_ATH:';
        String APPLICATION_STATUS = 'Approved';
        
        Id b2bRT = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('B2B').getRecordTypeId();
        System.debug( lprefix + 'processEmailsForApplicationApproval: - START');
        
        // Set up email util
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        if (emailSettings == null) System.debug('FLEET_EMAIL_SETTINGS__C MUST BE CONFIGURED TO SEND EMAILS');
        
        // get information for sendCreditAppAcceptedEmail
        String fromAddress = emailSettings.Fleet_CreditAppAcceptFromEmail__c;
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationAcceptedEmail__c);
        
        // get information for endCreditAppAcceptedWelcomeEmail
        String welcomeFromAddress = emailSettings.Fleet_CreditAppWelcomeFromEmail__c;
        String welcomeTemplateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCreditAppAcceptedEmail__c);
        List<OrgWideEmailAddress> welcomeOwaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :welcomeFromAddress];
        
        // List<PermissionSetAssignment> sfAdmins = [SELECT Assignee.Email FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Fleet_Business_Administrator'];
        
        Set<Id> sendEmailAccountIdList = new Set<Id>();
        //List<Id> accountsToCheckList = new List<Id>();		
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        
        // Check the list of account against the oldMap to make sure the ECC_Account_Number__c was blank before ensuring this was an inital record sync
        if(accountsToCheck.size() > 0){
            for(Account acct: accountsToCheck){
                
                if (acct.RecordTypeId != b2bRT) continue;
                
                if(!acct.Fleet_Account_Approval_Emails_Sent__c){      
                    
                    System.debug(acct.Fleet_Application_Type__c);
                    
                    System.debug('Send Credit App Emails');              
                    Fleet_AccountEmailUtil.sendCreditAppAcceptedEmail(emailSettings, acct.id, null, acct, owaList, templateId); // removed sfAdmins
                    sendEmailAccountIdList.add(acct.id); 
                }
                
                if(acct.SAP_Created_Date__c >= System.today().addDays(-1*Integer.valueOf(Label.Fleet_WelcomeEmailNumberOfDays)) && acct.Fleet_AR_App_Status__c == APPLICATION_STATUS){
                    acct.Welcome_Email_Triggered__c = false;
                    Fleet_AccountEmailUtil.sendCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, welcomeOwaList, welcomeTemplateId);
                    
                    // Set list of community users to be created
                    if(acct.Fleet_Primary_Contact__c != null){
                        contactIdSet.add(acct.Fleet_Primary_Contact__c);
                        accountIdSet.add(acct.Id);
                    }
                }
                
                
            }
        }
        
        // set a future method to update the Fleet_Account_Approval_Emails_Sent__c field to true
        if(sendEmailAccountIdList.size() > 0){
            // Create users for Community now that emails have been sent
            //processContactCommunityUsers(oldMap, newMap, sendEmailAccountIdList); 
            System.debug('account to update:');
            if(System.IsBatch() == false && System.isFuture() == false){ 
                Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(sendEmailAccountIdList);
            }
            
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
            Fleet_CommunityUserBuilder.convertContactToCommunityUser(contactIdSet);
        }
        
        
    }   
    
    // Finish Method
    
    global void finish(Database.BatchableContext BC) {
        
        system.debug('record processed'+recordcount);
    }
    
    global void execute(SchedulableContext sc) {
        Fleet_BatchWelcomeEmailCredit batch = new Fleet_BatchWelcomeEmailCredit(); 
        database.executebatch(batch, 1);
    }
    
    public static String schedule() {
        String schedule = '0 0 6,18 ? * *';
        Fleet_BatchWelcomeEmailCredit batch = new Fleet_BatchWelcomeEmailCredit(); 
        return System.schedule('Fleet_BatchWelcomeEmailCredit - Daily 6AM/6PM', schedule, batch);
    }
}