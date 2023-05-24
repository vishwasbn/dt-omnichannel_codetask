/***********************************************************************************************************************************
Name      : Fleet_EmailToActivityService 
Usage     : Class is responsible for handling inbound emails sent to the Salesforce org, converting them into EmailMessage objects and 
			linking them to the appropriate Account record. 
Date      : March 2023  
************************************************************************************************************************************/ 


global class Fleet_EmailToActivityService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        // Find the account based on the email address
        Account account;
        try {
			account = [SELECT Id, Name FROM Account WHERE Fleet_Primary_Contact__r.Email = :email.fromAddress LIMIT 1];
        } catch (Exception ex) {
            result.success = false;
            System.debug('Error :' + ex.getMessage());//Removed the error message sent to customer when an received sender was not part of the CRM. SF-1230.
            return result;
        }

        if (account == null) {
            result.success = false;
            return result;
        }
        
        // Create the EmailMessage and link it to the account
        EmailMessage message = new EmailMessage();
        message.FromAddress = email.fromAddress;
        message.ToAddress = email.toAddresses[0];
        message.Subject = email.subject;
        message.HtmlBody = email.htmlBody;
        message.TextBody = email.plainTextBody;
        message.Incoming = true;
        message.MessageDate = System.now();
        message.Status = '0';
        message.RelatedToId = account.Id;
        
            insert message;
            result.success = true;
        
        
        return result;
    }
}