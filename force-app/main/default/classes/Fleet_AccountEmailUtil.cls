/**
 Created By : John Bruning
 Creatted Dated :  10/30/2020, 3:49 PM
 Description : Update W9Form.
 Modified By : Rohith V
 Modified Date :  01/24/2023
 User Story Number : Salesforce-941.
#2
Modified By : Rohith V	
 Modified Date :  3/08/2023
 User Story Number : Salesforce-844.
 */
public class Fleet_AccountEmailUtil {
    public static String lprefix = 'FLEET_AEMAILU:';
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    public final static String STATUS_EXCEPTION = 'Exception';

    public static void sendCreditAppAcceptedEmail(Fleet_Email_Settings__c emailSettings, String accountId, List<PermissionSetAssignment> sfAdmins, Account acc, List<OrgWideEmailAddress> owaList, String templateId ) {
        System.debug(lprefix + 'sendCreditAppAcceptedEmail() ENTRY - accountId=' + accountId);
       
        //to-address => acc.Fleet_Primary_Contact__r.Email
        // do not send emails if settings are not configured
        if (emailSettings == null) return;
		System.debug('@@@@');
        // get email template names for Credit Accepted
        String templateName;
        String fromAddress;
        System.debug('@@@@');
        if(acc.AT_Customer__c){
            System.debug('@@@@');
            templateName = emailSettings.Fleet_CreditApplicationAcceptedEmail_AT__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Credit_App_Accept_From_Email_AT__c;
            System.debug('$$$$' + fromAddress);
        }else{
            System.debug('@@@@');
            templateName = emailSettings.Fleet_CreditApplicationAcceptedEmail__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Fleet_CreditAppAcceptFromEmail__c;
            System.debug('$$$$' + fromAddress);
        }
        System.debug('fromAddress '+fromAddress);
        String bccAddressString = emailSettings.Fleet_CreditAppAcceptBccEmails__c;
        System.debug('bccAddressString '+bccAddressString);
        List<String> bccAddressList = (bccAddressString != null && bccAddressString != '') ? bccAddressString.deletewhitespace().split(',') : new List<String>();
        System.debug('bccAddressList'+bccAddressList);
        // add on extra BCC from the pass parameter if it exists
        if ((sfAdmins != null) && (sfAdmins.size() > 0))
        {
            System.debug('@@@@');
            for (PermissionSetAssignment sfAdmin : sfAdmins) {
                System.debug('@@@@');
                bccAddressList.add(sfAdmin.Assignee.Email);
            }
        }
		
        sendApplicationEmail(templateName, accountId, bccAddressList, fromAddress, acc, owaList, templateId);
        System.debug(lprefix + 'sendCreditAppAcceptedEmail() EXIT');
    }


    // Trigger optimized
   public static void sendCreditAppAcceptedWelcomeEmail(Fleet_Email_Settings__c emailSettings, 
                                                        String accountId, Account acc, List<OrgWideEmailAddress> owaList, 
                                                        String templateId) {
        System.debug(lprefix + 'sendCreditAppAcceptedWelcomeEmail() ENTRY - accountId=' + accountId);

        // do not send emails if settings are not configured
        if (emailSettings == null) return;
        
        String templateName;
        String fromAddress;
        String bccAddressString = emailSettings.Fleet_CreditAppWelcomeBccEmails__c;
        List<String> bccAddressList = (bccAddressString != null && bccAddressString != '') ? bccAddressString.deletewhitespace().split(',') : new List<String>();
        if(acc.AT_Customer__c){
            templateName = emailSettings.Fleet_WelcomeCreditAppAcceptedEmail_AT__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Credit_App_Welcome_From_Email_AT__c;
            System.debug('$$$$' + fromAddress);
        }else{
            templateName = emailSettings.Fleet_WelcomeCreditAppAcceptedEmail__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Fleet_CreditAppWelcomeFromEmail__c;
            System.debug('$$$$' + fromAddress);
        }
        sendApplicationEmail(templateName, accountId, bccAddressList, fromAddress, acc, owaList, templateId);
        System.debug(lprefix + 'sendCreditAppAcceptedWelcomeEmail() EXIT');
    }

    // Trigger optimized
    public static void sendNonCreditAppAcceptedWelcomeEmail(Fleet_Email_Settings__c emailSettings, String accountId, Account acc, List<OrgWideEmailAddress> owaList, String templateId) {
        System.debug(lprefix + 'sendNonCreditAppAcceptedWelcomeEmail() ENTRY - accountId=' + accountId);

        // do not send emails if settings are not configured
        if (emailSettings == null) return;
        String templateName;
        String fromAddress;
        if(acc.AT_Customer__c){
            templateName = emailSettings.Fleet_WelcomeCashAppAcceptedEmail_AT__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Cash_App_Welcome_From_Email_AT__c;
            System.debug('$$$$' + fromAddress);
        }else{
            templateName = emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c;
            templateId = Fleet_AccountEmailUtil.getTemplateId(templateName);
            fromAddress = emailSettings.Fleet_CashAppWelcomeFromEmail__c;
            System.debug('$$$$' + fromAddress);
        }
            
        //String templateName = emailSettings.Fleet_WelcomeCashAppAcceptedEmail__c;
        String bccAddressString = emailSettings.Fleet_CashAppWelcomeBccEmails__c;
        List<String> bccAddressList = (bccAddressString != null && bccAddressString != '') ? bccAddressString.deletewhitespace().split(',') : new List<String>();
        
        sendApplicationEmail(templateName, accountId, bccAddressList, fromAddress, acc, owaList, templateId);
        System.debug(lprefix + 'sendNonCreditAppAcceptedWelcomeEmail() EXIT');
    }


    // Updates the flag on the account once the email has been sent
    @future
    public static void updateApprovalEmailSentFlag(Set<id> acctIds){

        Logger logInstance = Logger.getInstance();
        logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', 'Before Account update');
         
        // Get Accounts from the trigger call
        List<Account> accounts = [SELECT Fleet_Account_Approval_Emails_Sent__c FROM Account WHERE Id IN :acctIds];
        List<Account> lstAccounts = New List<Account>();
        // Change send email to true
        for(Account acct: accounts){
            if(!acct.Fleet_Account_Approval_Emails_Sent__c){
                acct.Fleet_Account_Approval_Emails_Sent__c = true;  
                lstAccounts.add(acct);
            }
            
        }
        if(!lstAccounts.isEmpty())
            update lstAccounts;
        // Make the update
        

    }


    //--------------------------------------

    // Handles Emails resulting from the Fleet Application Process, including acceptance, rejection, and welcome emails
    public static Fleet_AccountApprovalController.ResultWrapper sendApplicationEmail(String templateName, String accountId, List<String> bccAddressList, String fromAddress, Account acc, List<OrgWideEmailAddress> owaList, String templateId) {
        System.debug('$$## ==> ' + templateName);
        Fleet_AccountApprovalController.ResultWrapper emailResult = new Fleet_AccountApprovalController.ResultWrapper();
        
        //get email template id
        //String templateId = getTemplateId(templateName);
        // Don't send email if template is not found
        if (templateId == null) {
            emailResult.status = 'Template Not Found';
            emailResult.message = 'Unable to send email template: ' + templateName + ' to Account with Id: ' + accountId;
            return emailResult;
        }
        
        //Get Account and toAddress
        //Account acc = [select Id, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name from Account where Id = :accountId];
        String toAddress = acc.Fleet_Primary_Contact__r.Email; 
        System.debug(lprefix+'toAddress: ' + toAddress+'===='+fromAddress);
        System.debug('=====templateName==>'+templateName+'===='+acc.Selected_State__c);
        //Check for OWA
        //List<OrgWideEmailAddress> owaList = [select Id, DisplayName, Address from OrgWideEmailAddress where Address = :fromAddress];
        OrgWideEmailAddress owa = null; 
        //        if(!Label.Fleet_WelcomeEmailTemplates.contains(templateName) || (Label.Fleet_WelcomeEmailTemplates.contains(templateName) && Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c))){ 
        System.debug('$$$$$$$');
        //System.debug(templateName + '::' + Label.Fleet_WelcomeEmailTemplates.contains(templateName) + '::' + acc.Selected_State__c + '::' + Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c));
        System.debug('$$$$$$$');
        if((templateName!=null)&&(Label.Fleet_WelcomeEmailTemplates.contains(templateName))){
            if (acc.WelcomeEmailSent__c || acc.Welcome_Email_Triggered__c) return null;
            System.debug(lprefix+'Discount==>: ');
            System.debug('$$$$' + fromAddress);
            Fleet_DiscountImgPDFQueueable pdfimgJob = new Fleet_DiscountImgPDFQueueable(accountId,templateName,bccAddressList,fromAddress,acc,owaList,templateId);
            // enqueue the job for processing
            ID jobID = System.enqueueJob(pdfimgJob);
            Account objAcc = New Account(Id= acc.Id,Welcome_Email_Triggered__c=true);
            Update objAcc;
        }
        else if((templateName!=null)&&(!Label.Fleet_WelcomeEmailTemplates.contains(templateName) || (acc.Selected_State__c!=null && Label.Fleet_WelcomeEmailTemplates.contains(templateName) && Label.FleetDiscountImgExcludeState.contains(acc.Selected_State__c)))){ 
            
            
            if (owaList.size() > 0) {
                owa = owaList[0];
                System.debug(lprefix+'Setting OrgWideEmailAddress: ' + owa.Address + ' with display name: ' + owa.DisplayName);
            }
            
            //build email
            Messaging.SingleEmailMessage mail = buildEmail(new String[]{toAddress}, bccAddressList, fromAddress, owa, accountId, acc.Fleet_Primary_Contact__c, templateId);
            
            
            // send email
            
            try {
                Messaging.SendEmailResult[] result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug(lprefix+'Email Result: ' + result.toString());
                
                if (result.get(0).isSuccess()) {
                    if(Label.Fleet_WelcomeEmailTemplates.contains(templateName)){
                        acc.WelcomeEmailSent__c = true;
                        acc.Welcome_Email_Triggered__c = false;
                        system.debug('====WelcomeEmailSent__c>');
                       
                    }
                    emailResult.status = STATUS_SUCCESS;
                    emailResult.message = 'Email Successfully Sent!';
                }
                else {
                    acc.Welcome_Email_Triggered__c = false;
                    emailResult.status = STATUS_ERROR;
                    emailResult.message = JSON.serialize(result.get(0).getErrors());
                }
                 Update acc;
            } catch (exception e) {
                Logger logInstance = Logger.getInstance();
                logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', e);
                
                emailResult.status = STATUS_EXCEPTION;
                emailResult.message = e.getMessage();
                
            }
            System.debug(lprefix+'Result Wrapper: ' + emailResult);    
        }
        else{
            // do not send emails if Welcome Email is already Sent
            if (acc.WelcomeEmailSent__c || acc.Welcome_Email_Triggered__c) return null;
            System.debug(lprefix+'Discount==>: ');
            System.debug('$$$$' + fromAddress);
            Fleet_DiscountImgPDFQueueable pdfimgJob = new Fleet_DiscountImgPDFQueueable(accountId,templateName,bccAddressList,fromAddress,acc,owaList,templateId);
            // enqueue the job for processing
            ID jobID = System.enqueueJob(pdfimgJob);
            Account objAcc = New Account(Id= acc.Id,Welcome_Email_Triggered__c=true);
            Update objAcc;
        }
        return emailResult;
    }


    public static Messaging.SingleEmailMessage buildEmail(List<String> toAddresses, List<String> bccAddresses, String fromAddress, OrgWideEmailAddress owa, Id whatId, Id targetObjectId, Id templateId) {
        
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        String senderDisplayName = emailSettings.Fleet_SenderDisplayName__c;
        System.debug(lprefix+'BUILD EMAIL');
        // System.debug(lprefix+'BCC Addresses: ' + bccAddresses);
        // System.debug(lprefix+'Sender display name: ' + senderDisplayName);
        System.debug('=====toAddress:==>>>>>>>>> ' + toAddresses);
        // System.debug(lprefix+'fromAddress: ' + fromAddress);
        // System.debug(lprefix+'owaId: ' + owaId);

        // Build
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (owa != null) {
            mail.setOrgWideEmailAddressId(owa.Id);
        } else {
            mail.setReplyTo(fromAddress);
            mail.setSenderDisplayName(senderDisplayName);
        }
    
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :fromAddress];
		if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        mail.setBccAddresses(bccAddresses);
        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(true);
        mail.setWhatId(whatId);
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetObjectId);
        if(mail.getTemplateName() == 'Fleet Credit Application Accepted_DT'){
            Attachment[] a = [SELECT ContentType, Body From Attachment where parentId = :templateId];
            Blob imgBody;
            if(!test.isRunningTest()){
                imgBody = (a[0].Body);
            }else{
                imgBody=blob.valueOf('TestString');
            }
            
            Logger logInstance = Logger.getInstance();
            logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', 'Before ContentVersion insert');
            ContentVersion contentVersion_2 = new ContentVersion(
                Title=' W9 Form', 
                PathOnClient ='W9Form.pdf',
                VersionData = imgBody, 
                origin = 'H',
                FirstPublishLocationId = whatId
            );
            insert contentVersion_2;
            logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', 'After ContentVersion insert', JSON.serialize(contentVersion_2));
            //mail.setEntityAttachments(New List<Id>{contentVersion_2.Id});
        }
        //Added below code to insert content variable for AT SF-870
        else if(mail.getTemplateName() == 'Fleet Credit Application Accepted_AT'){
            Attachment[] a = [SELECT ContentType, Body From Attachment where parentId = :templateId];
            Blob imgBody;
            if(!test.isRunningTest()){
                imgBody = (a[0].Body);
            }else{
                imgBody=blob.valueOf('TestString');
            }
            
            Logger logInstance = Logger.getInstance();
            logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', 'Before ContentVersion insert');
            ContentVersion contentVersion_2 = new ContentVersion(
                Title=' W9 Form', 
                PathOnClient ='W9Form.pdf',
                VersionData = imgBody, 
                origin = 'H',
                FirstPublishLocationId = whatId
            );
            insert contentVersion_2;
            logInstance.log('Account Email Util', 'Fleet_AccountEmailUtil', 'After ContentVersion insert', JSON.serialize(contentVersion_2));
            //mail.setEntityAttachments(New List<Id>{contentVersion_2.Id});
        }
       // mail.IsClientManaged = false;setEntityAttachments
        system.debug('====mail=>'+mail);
        
        return mail;
    }

    public static String getTemplateId(String emailTemplateName) {
        List<EmailTemplate> templateList = [select Id from EmailTemplate where DeveloperName = :emailTemplateName limit 1];
        
        //---Handle email template not found
        if (templateList.size() < 1) {
            System.debug('No email Template found with name: ' + emailTemplateName);
            return null;
        }
        return templateList[0].Id;
    }
    

    public static void send7thDayCreditAppDeclinedEmail(List<Account> accounts) {
        String logPrefix = 'send7thDayCreditAppDeclinedEmail() ENTRY - ';
        System.debug(logPrefix + 'Started.');
        
        // Do not send emails if email settings are not configured
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getInstance();
        if (emailSettings == null) {
            System.debug(logPrefix + 'Email settings not found. Exiting.');
            return;
        }
        
        // Get org-wide email addresses
        List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :emailSettings.Fleet_CreditAppDeclinedFromEmail__c];
        if (owaList.isEmpty()) {
            System.debug(logPrefix + 'Org-wide email address not found. Exiting.');
            return;
        }
        
        for (Account acc : accounts) {
            // Check if account meets criteria for declined accounts
            if (acc.Fleet_Pending_Additional_Info_Date__c != null
                && acc.Fleet_Credit_App_Status__c == 'Declined'
                && acc.Fleet_Account_Status__c == 'Declined'
                && acc.Fleet_Days_Until_Decline__c == 0
                && !acc.Decline_7thday_email_sent__c) {
                    
                    // Determine template based on account type
                    String templateId = acc.AT_Customer__c
                        ? Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationDeclinedEmail_AT__c)
                        : Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_CreditApplicationDeclinedEmail__c);
                    
                    // Get BCC addresses from settings
                    List<String> bccAddressList = new List<String>();
                    String bccAddressString = emailSettings.Fleet_CreditAppDeclinedBccEmails__c;
                    if (!String.isBlank(bccAddressString)) {
                        bccAddressList = bccAddressString.deleteWhitespace().split(',');
                    }
                    
                    // Create email message
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setBccAddresses(bccAddressList);       
                    email.setTemplateId(templateId);
                    email.setOrgWideEmailAddressId(owaList[0].Id);
                    System.debug(owaList[0].Id);
                    email.setTargetObjectId(acc.Fleet_Primary_Contact__c);
                    email.setSubject('Your Fleet Application');
                    String emailBody = Messaging.renderStoredEmailTemplate(templateId, null, acc.Id).getHtmlBody();
                    email.setHtmlBody(emailBody);
                    
                    // Send email
               Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
                if (results[0].isSuccess()) {
                System.debug(logPrefix + 'Email sent successfully.');
                // Mark account as having the 7th day declined email sent
                acc.Decline_7thday_email_sent__c = true;
            } else {
                System.debug(logPrefix + 'Failed to send email: ' + results[0].getErrors()[0].getMessage());
            }
        } else {
            System.debug(logPrefix + 'Account does not meet criteria for declined accounts. Exiting.');
        	}
    	}
    }
    
    //Method to send the inactivity email to customer(SF-1025).
    public static void sendInactivityEmail(List<Account> accounts) {
        String logPrefix = 'sendInactivityEmail() ENTRY - ';
        System.debug(logPrefix + 'Started.');
        
        // Do not send emails if email settings are not configured
        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getInstance();
        if (emailSettings == null) {
            System.debug(logPrefix + 'Email settings not found. Exiting.');
            return;
        }
        
        // Create list of account records to update Fleet_Inactivity_Notification_Date__c
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : accounts) {
            // Get org-wide email address based on account type
            String fromAddress = acc.AT_Customer__c ? emailSettings.Fleet_Inactivity_From_Email_AT__c : emailSettings.Fleet_Inactivity_From_Email_DT__c;
            List<OrgWideEmailAddress> owaList = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :fromAddress];
            if (owaList.isEmpty()) {
                System.debug(logPrefix + 'Org-wide email address not found. Exiting.');
                return;
            }
            
            // Determine template based on account type
            String templateId = acc.AT_Customer__c
                ? Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_Inactivity_Email_AT__c)
                : Fleet_AccountEmailUtil.getTemplateId(emailSettings.Fleet_Inactivity_Email_DT__c);
            
            // Create email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{acc.Fleet_Primary_Contact__r.Email});
            email.setTemplateId(templateId);
            email.setOrgWideEmailAddressId(owaList[0].Id);
            System.debug(owaList[0].Id);
            email.setTargetObjectId(acc.Fleet_Primary_Contact__c);
            String emailSub = Messaging.renderStoredEmailTemplate(templateId, null, acc.Id).getSubject();
            email.setSubject(emailSub);
            String emailBody = Messaging.renderStoredEmailTemplate(templateId, null, acc.Id).getHtmlBody();
            email.setHtmlBody(emailBody);
    
            // Update Fleet_Inactivity_Notification_Date__c field to current date and time
            acc.Fleet_Inactivity_Notification_Date__c = DateTime.now();
            
            // Add account record to list for update
            accountsToUpdate.add(acc);
    
            // Send email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    
            if (results[0].isSuccess()) {
                System.debug(logPrefix + 'Email sent successfully.');
            } else {
                System.debug(logPrefix + 'Failed to send email: ' + results[0].getErrors()[0].getMessage());
            }
        }
        
        // Update all account records at once
        update accountsToUpdate;
    }


        
}