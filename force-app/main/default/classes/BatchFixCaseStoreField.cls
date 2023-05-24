global class BatchFixCaseStoreField implements Database.Batchable<sObject> {
    
    // Get the Cases whose new store field is null
    String query = 'Select Store__c, Store_New__c from Case where Store_New__c = null and Store__c != null';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);                
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Create an array of store names
        Set<String> storeNameList = new Set<String>();
        List<Case> casesToUpdate = new List<Case>();
        
        // Find store names
        for(Case c : (List<Case>) scope) {
            String name = c.Store__c.trim();
			name = name.replaceAll('(\\s+)', '');
            name = name.replaceAll('_', '');
            storeNameList.add(name);
        }
        
        // Query the stores
        List<Store__c> stores = [select id, Name from Store__c where Name in :storeNameList];
        
        // Create a store map
        Map<String, ID> storeMap = new Map<String, ID>();
        for(Store__c store : stores) {
            storeMap.put(store.Name.toUpperCase(), store.id);
        }
        
        // Loop through Cases and find the correct store
        for(Case c : (List<Case>) scope) {
            String name = c.Store__c.trim();
			name = name.replaceAll('(\\s+)', '');
            name = name.replaceAll('_', '');
            if(storeMap != null && storeMap.get(name.toUpperCase()) != null) {                
                c.Store_New__c = storeMap.get(name.toUpperCase());
                casesToUpdate.add(c);
            }         
        }
        
        // Update the database
        if(casesToUpdate.size() > 0)
            update casesToUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}