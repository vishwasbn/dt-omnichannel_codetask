global class BatchUpdateMBWheelsCases implements Database.Batchable<sObject> {
// Default query
    String query = 'Select id, Parent.Store_New__c From EmailMessage where ToAddress = \'admin@wheelsbymbmotoring.com\'';
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){ List<Case> casesToUpdate = new List<Case>(); Set<ID> caseIds = new Set<ID>();for(EmailMessage email : (List<EmailMessage>) scope) {caseIds.add(email.ParentId);} casesToUpdate = [select Store_New__c from Case where id in :caseIds];for(Case c : casesToUpdate) {c.Store_New__c = 'a05E000000Ifv2X';} if(casesToUpdate.size() > 0)update casesToUpdate; }
        
        
        // Loop through scope and set store to MB_Wheels
        
        
        
        
        // Update store
        
        
        // Update the cases
       
    
    
    global void finish(Database.BatchableContext BC){     
        // nothing
    }
}