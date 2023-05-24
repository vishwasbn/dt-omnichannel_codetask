global class BatchFixResponseTimeFields implements Database.Batchable<sObject> {
    
    // Get the Cases whose new store field is null
    String query = 'Select CreatedDate,Last_Status_Change__c,Time_With_Support__c,Time_With_Customer__c from Case where Last_Status_Change__c= null';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);                
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Create an array of store names
       
        List<Case> casesToUpdate = new List<Case>();
        
        
        // Loop through Cases and find the correct store
        for(Case c : (List<Case>) scope) {
            

            //update fields for response calculations
            if(c.Last_Status_Change__c == null) c.Last_Status_Change__c = c.CreatedDate;
            if(c.Time_With_Support__c == null) c.Time_With_Support__c = 0.0;
            if(c.Time_With_Customer__c == null) c.Time_With_Customer__c = 0.0;

            casesToUpdate.add(c);
        }
        
        // Update the database
        if(casesToUpdate.size() > 0)
            update casesToUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}