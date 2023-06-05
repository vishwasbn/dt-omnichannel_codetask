global class BatchDeleteOutgoingEmailAttachments implements Database.Batchable<sObject> {
    // Default query
    String query = 'Select id From EmailMessage Where Incoming = false';
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<ID> emailIds = new List<ID>();
        List<EmailMessage> emails = new List<EmailMessage>();
        
        // Loop through scope to find email ids
        for(EmailMessage email : (List<EmailMessage>) scope) {
            emailIds.add(email.id);
        }
        
        // Find attachments for these emails
        List<Attachment> attachments = [select id from Attachment where ParentId IN :emailIds];
        
        // Delete the attachments
        if(attachments.size() > 0)
            delete attachments;
    }
    
    global void finish(Database.BatchableContext BC){     
        // nothing
    }
}