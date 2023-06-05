global class BatchUpdateAccountMultipleCaseCheckbox implements Database.Batchable<sObject> {
    
    // Default query
    String query = 'Select Has_Multiple_Cases__c, (Select id From Cases) From Account where Has_Multiple_Cases__c = false';
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);        
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Account> accountsToUpdate = new List<Account>();
        
        // Loop through scope to find accounts with multiple cases
        for(Account account : (List<Account>) scope) {
        	// Check for multiple cases
            if(account.Cases.size() > 1) {
                account.Has_Multiple_Cases__c = true;
                accountsToUpdate.add(account);
            }
        }
        
        // Update the accounts
        if(accountsToUpdate.size() > 0)
            update accountsToUpdate;
    }
    
    global void finish(Database.BatchableContext BC){     
        // nothing
    }
}