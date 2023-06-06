public with sharing class Fleet_ApplicationEmailController {

    public static String lprefix = 'FLEET_AEC:';
    public final static String STATUS_SUCCESS = 'Success';
    public final static String STATUS_ERROR = 'Error';
    public final static String STATUS_EXCEPTION = 'Exception';


    // Handles Emails resulting from the Fleet Application Process, including acceptance, rejection, and welcome emails
    public static Fleet_AccountApprovalController.ResultWrapper sendApplicationEmail(String templateName, String accountId, List<String> bccAddressList, String fromAddress) {
        Fleet_AccountApprovalController.ResultWrapper emailResult = new Fleet_AccountApprovalController.ResultWrapper();
        
        //get email template id
        String templateId = getTemplateId(templateName);
        // Don't send email if template is not found
        if (templateId == null) {
            emailResult.status = 'Template Not Found';
            emailResult.message = 'Unable to send email template: ' + templateName + ' to Account with Id: ' + accountId;
            return emailResult;
        }
        
        //Get Account and toAddress
        Account acc = [select Id, Fleet_Primary_Contact__c, Fleet_Primary_Contact__r.Email, Name from Account where Id = :accountId];
        String toAddress = acc.Fleet_Primary_Contact__r.Email; 
        System.debug(lprefix+'toAddress: ' + toAddress);

        //Check for OWA
        List<OrgWideEmailAddress> owaList = [select Id, DisplayName, Address from OrgWideEmailAddress where Address = :fromAddress];
        OrgWideEmailAddress owa = null;
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
                emailResult.status = STATUS_SUCCESS;
                emailResult.message = 'Email Successfully Sent!';
            }
            else {
                emailResult.status = STATUS_ERROR;
                emailResult.message = JSON.serialize(result.get(0).getErrors());
            }

        } catch (exception e) {
            Logger logInstance = Logger.getInstance();
            logInstance.log('Application Email', 'Fleet_ApplicationEmailController', e);
            
            emailResult.status = STATUS_EXCEPTION;
            emailResult.message = e.getMessage();
            
        }
        System.debug(lprefix+'Result Wrapper: ' + emailResult);
        return emailResult;
    }


    public static Messaging.SingleEmailMessage buildEmail(List<String> toAddresses, List<String> bccAddresses, String fromAddress, OrgWideEmailAddress owa, Id whatId, Id targetObjectId, Id templateId) {

        Fleet_Email_Settings__c emailSettings = Fleet_Email_Settings__c.getOrgDefaults();
        String senderDisplayName = emailSettings.Fleet_SenderDisplayName__c;
        System.debug(lprefix+'BUILD EMAIL');
        // System.debug(lprefix+'BCC Addresses: ' + bccAddresses);
        // System.debug(lprefix+'Sender display name: ' + senderDisplayName);
        // System.debug(lprefix+'toAddress: ' + toAddresses);
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

        mail.setBccAddresses(bccAddresses);
        mail.setToAddresses(toAddresses);
        mail.setUseSignature(false);
        mail.setSaveAsActivity(true);
        mail.setWhatId(whatId);
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetObjectId); 

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
    
}