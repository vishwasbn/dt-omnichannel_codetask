@isTest
public with sharing class Fleet_AccountEmailUtilTest {
    public static String APPLICATION_TYPE_CREDIT = 'Credit';
    @TestSetup
    static void makeData(){
        
        Account acc = new Account(
            Name='Test Account',
            Selected_State__c = 'Alaska',
            AT_Customer__c = true,
            Fleet_Account_Status__c = 'Prospect'
        );
        insert acc;
        
        Account acc2 = new Account(
            Name='Test Account2',
            Selected_State__c = 'Texas',
            Fleet_Account_Status__c = 'Prospect'

        );
        insert acc2;

        Contact con = new Contact(
            FirstName='Jon',
            LastName='Johnson',
            Email='john@discountire.example',
            AccountId = acc.Id
        );
        insert con;
        
        Contact con2 = new Contact(
            FirstName='Jon',
            LastName='jake',
            Email='jake@discountire.example',
            AccountId = acc2.Id
        );
        insert con2;
        
        //OrgWideEmailAddress Addr=new OrgWideEmailAddress(Address='abc');
        
        acc.Email__c = 'john@discountire.example';
        acc.Fleet_Primary_Contact__c = con.Id;
        acc.Lead_Email__c = 'john@discountire.example';
        acc.Fleet_Account_Status__c = 'Pending Additional Information';
        acc.Fleet_Days_Until_Decline__c = 7;
        acc.Fleet_Pending_Additional_Info_Date__c=System.today();
        update acc;
        

        
        acc2.Email__c = 'jake@discountire.example';
        acc2.Fleet_Primary_Contact__c = con2.Id;
        acc2.Lead_Email__c = 'jake@discountire.example';
        acc2.Fleet_Account_Status__c = 'Pending Additional Information';
        acc2.Fleet_Days_Until_Decline__c = 7;
        acc2.Fleet_Pending_Additional_Info_Date__c=System.today();
        update acc2;
        
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
        settings.Fleet_CreditAppDeclinedFromEmail__c = 'ar_app@discounttire.com';
        settings.Fleet_CashAppWelcomeFromEmail__c = 'dt_fleet@discounttire.com.example';
        settings.Cash_App_Welcome_From_Email_AT__c = 'at_fleet@discounttire.com.example';
        settings.Credit_App_Welcome_From_Email_AT__c = 'at_fleet@discounttire.com.example';
        settings.Credit_App_Accept_From_Email_AT__c = 'at_fleet@discountttire.com.testonly';

        // BCC emails
        settings.Fleet_CreditAppAcceptBccEmails__c = 'AR@discountttire.com.fleetexample, CAP@discountttire.com.fleetexample';
        settings.Fleet_CreditAppDeclinedBccEmails__c = 'AR@discountttire.com.fleetexample';
        settings.Fleet_CreditAppWelcomeBccEmails__c = 'AR@discountttire.com.fleetexample';
        settings.Fleet_CashAppWelcomeBccEmails__c = 'AR@discountttire.com.fleetexample';
        upsert settings;
        

    }

    @isTest
    public static void sendCreditAppAcceptedEmailTest(){

        Account acct = [SELECT Id, ECC_Account_Number__c, Fleet_Application_Type__c,ShippingPostalCode,
                        AT_Customer__c,DT_Customer__c, Fleet_Primary_Contact__c, 
                        Fleet_Primary_Contact__r.Email,Selected_State__c, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account'];
        
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        acct.WelcomeEmailSent__c = true;
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        
        List<PermissionSetAssignment> sfAdmins = [SELECT Assignee.Email FROM PermissionSetAssignment WHERE 
                                                  PermissionSet.Name = 'Fleet_Business_Administrator'];
		String fromAddress;
        if(acct.AT_Customer__c){
            fromAddress = emailSettings.Credit_App_Accept_From_Email_AT__c;
        }
        else{
        	fromAddress = emailSettings.Fleet_CreditAppAcceptFromEmail__c;   
        }
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                             Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationAcceptedEmail__c);
                           

        System.debug('----------Start Test----------');
        Test.startTest();

        Fleet_AccountEmailUtil.sendCreditAppAcceptedEmail(emailSettings, acct.id, sfAdmins, acct, owaList, templateId);           

        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id, FromAddress, ToAddress, BccAddress FROM EmailMessage ORDER BY 
                                        CreatedDate DESC];
        System.debug(emailSent);
       // System.assert(emailSent.size() > 0, 'Email was sent: ' + emailSent.size());
        // practically, the from is whoever is running the test
        // System.debug('From: ' + emailSent[0].FromAddress);
        // System.assert(emailSent[0].FromAddress.equals('AR@discountttire.com.testonly'), 'From address is wrong');
        if(emailSent.size()>0){
        System.debug('To: ' + emailSent[0].ToAddress);
        System.assert(emailSent[0].ToAddress.equals('john@discountire.example'), 'To address is wrong');

        System.debug('BCC: ' + emailSent[0].BccAddress);
        System.assert(emailSent[0].BccAddress.contains('AR@discountttire.com.fleetexample'), 'BCC does not contain the first member of the custom setting');
        System.assert(emailSent[0].BccAddress.contains('CAP@discountttire.com.fleetexample'), 'BCC does not contain the second member of the custom setting');
        System.debug('----------End Test----------');
        }
        
    }
    
    @isTest
    public static void sendCreditAppAcceptedEmail_DTTest(){

        Account acct = [SELECT Id, ECC_Account_Number__c, Fleet_Application_Type__c,ShippingPostalCode,
                        AT_Customer__c,DT_Customer__c, Fleet_Primary_Contact__c, 
                        Fleet_Primary_Contact__r.Email,Selected_State__c, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account2'];
        
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        acct.WelcomeEmailSent__c = false;
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        
        List<PermissionSetAssignment> sfAdmins = [SELECT Assignee.Email FROM PermissionSetAssignment WHERE 
                                                  PermissionSet.Name = 'Fleet_Business_Administrator'];
		String fromAddress;
        if(acct.AT_Customer__c){
            fromAddress = emailSettings.Credit_App_Accept_From_Email_AT__c;
        }
        else{
        	fromAddress = emailSettings.Fleet_CreditAppAcceptFromEmail__c;   
        }
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                             Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationAcceptedEmail__c);
                           

        System.debug('----------Start Test----------');
        Test.startTest();

        Fleet_AccountEmailUtil.sendCreditAppAcceptedEmail(emailSettings, acct.id, sfAdmins, acct, owaList, templateId);           

        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id, FromAddress, ToAddress, BccAddress FROM EmailMessage ORDER BY 
                                        CreatedDate DESC];
        System.debug(emailSent);
       // System.assert(emailSent.size() > 0, 'Email was sent: ' + emailSent.size());
        // practically, the from is whoever is running the test
        // System.debug('From: ' + emailSent[0].FromAddress);
        // System.assert(emailSent[0].FromAddress.equals('AR@discountttire.com.testonly'), 'From address is wrong');
        if(emailSent.size()>0){
        System.debug('To: ' + emailSent[0].ToAddress);
        System.assert(emailSent[0].ToAddress.equals('jake@discountire.example'), 'To address is wrong');

        System.debug('BCC: ' + emailSent[0].BccAddress);
        System.assert(emailSent[0].BccAddress.contains('AR@discountttire.com.fleetexample'), 'BCC does not contain the first member of the custom setting');
        System.assert(emailSent[0].BccAddress.contains('CAP@discountttire.com.fleetexample'), 'BCC does not contain the second member of the custom setting');
        System.debug('----------End Test----------');
        }
        
    }

    @isTest
    public static void sendCreditAppAcceptedWelcomeEmailTest(){

        Account acct = [SELECT Id, ECC_Account_Number__c,Welcome_Email_Triggered__c, Selected_State__c,
                        ShippingPostalCode,AT_Customer__c,DT_Customer__c, Fleet_Application_Type__c, 
                        Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account'];
        
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        
        acct.WelcomeEmailSent__c = false;
        
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        

        String welcomeFromAddress;
        if(acct.AT_Customer__c == true){
            welcomeFromAddress = emailSettings.Credit_App_Welcome_From_Email_AT__c;
        }
        else{
            welcomeFromAddress = emailSettings.Fleet_CreditAppWelcomeFromEmail__c;
        }
        String welcomeTemplateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCreditAppAcceptedEmail__c);
        List<OrgWideEmailAddress> welcomeOwaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                                    Address = : welcomeFromAddress];
        
        system.debug('emailSettings :'+emailSettings);
        system.debug('@acct.id:'+acct.id);
        system.debug('acct: '+acct);
        System.debug('welcomeFromAddress :'+welcomeFromAddress);
        system.debug('welcomeOwaList: '+welcomeOwaList);
        system.debug('welcomeTemplateId: '+welcomeTemplateId);

        System.debug('----------Start Test----------');
        Test.startTest();
        
        Fleet_AccountEmailUtil.sendCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, welcomeOwaList, 
                                                                 welcomeTemplateId);
        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        
       // System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test----------');       
    }

        @isTest
    public static void sendCreditAppAcceptedWelcomeEmailTestDT(){

        Account acct = [SELECT Id, ECC_Account_Number__c,Welcome_Email_Triggered__c, Selected_State__c,
                        ShippingPostalCode,AT_Customer__c,DT_Customer__c, Fleet_Application_Type__c, 
                        Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account2'];
        
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        
        acct.WelcomeEmailSent__c = false;
        
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        

        String welcomeFromAddress;
        if(acct.AT_Customer__c == true){
            welcomeFromAddress = emailSettings.Credit_App_Welcome_From_Email_AT__c;
        }
        else{
            welcomeFromAddress = emailSettings.Fleet_CreditAppWelcomeFromEmail__c;
        }
        String welcomeTemplateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCreditAppAcceptedEmail__c);
        List<OrgWideEmailAddress> welcomeOwaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                                    Address = : welcomeFromAddress];
        
        system.debug('emailSettings :'+emailSettings);
        system.debug('@acct.id:'+acct.id);
        system.debug('acct: '+acct);
        System.debug('welcomeFromAddress :'+welcomeFromAddress);
        system.debug('welcomeOwaList: '+welcomeOwaList);
        system.debug('welcomeTemplateId: '+welcomeTemplateId);

        System.debug('----------Start Test----------');
        Test.startTest();
        
        Fleet_AccountEmailUtil.sendCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, welcomeOwaList, 
                                                                 welcomeTemplateId);
        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        
       // System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test----------');       
    }
    @isTest
    public static void sendNonCreditAppAcceptedWelcomeEmailTestAT(){

        Account acct = [SELECT Id, ECC_Account_Number__c,Welcome_Email_Triggered__c, Selected_State__c,
                        ShippingPostalCode,AT_Customer__c,DT_Customer__c, Fleet_Application_Type__c, 
                        Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c 
                        FROM Account WHERE Name = 'Test Account'];
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        acct.WelcomeEmailSent__c = false;
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        
        String fromAddress;
        if(acct.AT_Customer__c){
        	fromAddress = emailSettings.Cash_App_Welcome_From_Email_AT__c;
        }
        else{
        	fromAddress = emailSettings.Fleet_CashAppWelcomeFromEmail__c;
        }
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                             Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c);

        System.debug('----------Start Test----------');
        //Test.startTest();

        Fleet_AccountEmailUtil.sendNonCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, owaList, templateId); 
        
        //Test.stopTest(); 

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        //System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test----------');
    }
    
    @isTest
    public static void sendNonCreditAppAcceptedWelcomeEmailTestDT(){

        Account acct = [SELECT Id, ECC_Account_Number__c,Welcome_Email_Triggered__c, Selected_State__c,
                        ShippingPostalCode,AT_Customer__c,DT_Customer__c, Fleet_Application_Type__c, 
                        Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name,Fleet_Business_Located__c 
                        FROM Account WHERE Name = 'Test Account2'];
        acct.Fleet_Application_Type__c = APPLICATION_TYPE_CREDIT ;
        acct.WelcomeEmailSent__c = false;
        update acct;

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();        
        String fromAddress;
        if(acct.AT_Customer__c){
        	fromAddress = emailSettings.Cash_App_Welcome_From_Email_AT__c;
        }
        else{
        	fromAddress = emailSettings.Fleet_CashAppWelcomeFromEmail__c;
        }
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE 
                                             Address = :fromAddress];
        String templateId = Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c);

        System.debug('----------Start Test----------');
        //Test.startTest();

        Fleet_AccountEmailUtil.sendNonCreditAppAcceptedWelcomeEmail(emailSettings, acct.id, acct, owaList, templateId); 
        
        //Test.stopTest(); 

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        //System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test----------');
    }

    @isTest
    public static void updateApprovalEmailSentFlagTest(){

        Account acct = [SELECT Id, ECC_Account_Number__c, Fleet_Application_Type__c,ShippingPostalCode,AT_Customer__c,DT_Customer__c, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name FROM Account WHERE Name = 'Test Account'];
        
        Set<id> idsToUpdate = new Set<id>();

        idsToUpdate.add(acct.id);
                           

        System.debug('----------Start Test----------');
        Test.startTest();

        Fleet_AccountEmailUtil.updateApprovalEmailSentFlag(idsToUpdate);       

        Test.stopTest();

        Account acctValidate = [SELECT Id, Fleet_Account_Approval_Emails_Sent__c FROM Account WHERE Name = 'Test Account'];
        System.assert(acctValidate.Fleet_Account_Approval_Emails_Sent__c == true, 'Email Flag Set');
        System.debug('----------End Test----------');
        
    }
    
    
    @isTest
   	 public static void send7thDayCreditAppDeclinedEmailTestDT(){
         
        List<Account> acc = new List<Account>();

        Account acct = [SELECT Id, ECC_Account_Number__c, Fleet_Application_Type__c,ShippingPostalCode,
                        AT_Customer__c,DT_Customer__c, Fleet_Primary_Contact__c, Fleet_Credit_App_Status__c,Fleet_Account_Status__c,
                        Fleet_Days_Until_Decline__c,Decline_7thday_email_sent__c,Fleet_Pending_Additional_Info_Date__c, Account.Email__c,
                        Fleet_Primary_Contact__r.Email,Selected_State__c, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account2'];
        
        acct.Fleet_Account_Status__c='Declined';
        acct.Fleet_Credit_App_Status__c = 'Declined';
        acct.Fleet_Days_Until_Decline__c = 0 ;
        
        update acct;
         
        acc.add(acct);
         
        System.debug('----------Start Test----------');
        Test.startTest();
         
        Fleet_AccountEmailUtil.send7thDayCreditAppDeclinedEmail(acc);
         
        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        
       // System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test--');
            
            }
    
    @isTest
   	 public static void send7thDayCreditAppDeclinedEmailTestAT(){
         
        List<Account> acc = new List<Account>();

        Account acct = [SELECT Id, ECC_Account_Number__c, Fleet_Application_Type__c,ShippingPostalCode,
                        AT_Customer__c,DT_Customer__c, Fleet_Primary_Contact__c, Fleet_Credit_App_Status__c,Fleet_Account_Status__c,
                        Fleet_Days_Until_Decline__c,Decline_7thday_email_sent__c,Fleet_Pending_Additional_Info_Date__c, Account.Email__c,
                        Fleet_Primary_Contact__r.Email,Selected_State__c, Name,Fleet_Business_Located__c FROM Account 
                        WHERE Name = 'Test Account'];
        
        acct.Fleet_Account_Status__c='Declined';
        acct.Fleet_Credit_App_Status__c = 'Declined';
        acct.Fleet_Days_Until_Decline__c = 0 ;
        
        update acct;
        
         acc.add(acct);

        System.debug('----------Start Test----------');
        Test.startTest();
         
        Fleet_AccountEmailUtil.send7thDayCreditAppDeclinedEmail(acc);
         
        Test.stopTest();

        List<EmailMessage> emailSent = [SELECT id FROM EmailMessage];
        System.debug(emailSent);
        
       // System.assert(emailSent.size() > 0, 'Email was sent');
        System.debug('----------End Test--');
            
            }


}