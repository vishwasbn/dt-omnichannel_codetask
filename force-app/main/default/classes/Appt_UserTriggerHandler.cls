public without sharing class Appt_UserTriggerHandler {
    public static String lprefix = 'LOG_UserApptSetup:';

    public static Map<id, String> deleteMap = new Map<id, String> ();
    public static Map<id, String> createMap = new Map<id, String> ();
    public static Set<String> allStoresIds = new Set<String>();
    public static Set<id> allStoresSalesforceIds = new Set<id>();
    public static Set<id> userUpdateSet = new Set<id>();
    public static Map<String, id> sapIdMap =  new Map<String, id>();
    public static Map<String, id> storeIdMap =  new Map<String, id>();

    public static List<ServiceTerritory> matchStoreList = new List<ServiceTerritory>();
    public static List<ServiceTerritoryShare> existingSharedStoresList = new List<ServiceTerritoryShare>();
    public static List<ServiceTerritoryShare> newSharedStoresList = new List<ServiceTerritoryShare>();
    public static List<ServiceTerritoryShare> deleteSharedStoresList = new List<ServiceTerritoryShare>();
    public static final String SHARE_REASON = 'Manual';
    public static final String SHARE_ACCESS = 'Read';

    // top level handle method that is used to evaluate if share records are 
    public static void handle(Map<Id, User> oldMap, Map<Id, User> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Appt UserTriggerHandler Handler - START');
        // refresh the lists in case the trigger runs more than once in one context
        List<ServiceTerritoryShare> clearNewSharedStoresList = new List<ServiceTerritoryShare>();
        List<ServiceTerritoryShare> cleardeleteSharedStoresList = new List<ServiceTerritoryShare>();
        newSharedStoresList = clearNewSharedStoresList;
        deleteSharedStoresList = cleardeleteSharedStoresList;
        
        switch on triggerEvent 
        {
            when AFTER_INSERT {                
                if(filterToUpdateRecords(oldMap,newMap)){
                    updateUserAccess(oldMap,newMap);
                }
            }            
            when AFTER_UPDATE {
                if(filterToUpdateRecords(oldMap,newMap)){
                    updateUserAccess(oldMap,newMap);
                }
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + ' Appt UserTriggerHandler Handler - END');
    }

    // filter out records to only records that have a change on the user store id field
    public static Boolean filterToUpdateRecords(Map<Id, User> oldMap, Map<Id, User> newMap){
        System.debug(lprefix + ' filterToUpdateRecords - START');
        Boolean processUsers = false;
        Boolean createUser = true;

        // loop through users to check what kind of changes are being made
        for (User newUser: newMap.values()) {
            String oldValue;
            String newValue = newUser.User_Store_Id__c;

            System.debug(lprefix + ' old value:' + oldValue);
            System.debug(lprefix + ' new value:' + newValue);

            if(oldMap != null){
                oldValue = oldMap.get(newUser.id).User_Store_Id__c;
                userUpdateSet.add(newUser.id);
                createUser = false;
            } 

            // new user assigned a store or user updated from no store to having a store
            if(oldValue == null && newValue != null){
                userUpdateSet.add(newUser.id);
                createMap.put(newUser.id, newValue);
            }

            // Clearing a users store but not adding a new one
            if(oldValue != null && newValue == null){
                userUpdateSet.add(newUser.id);
                deleteMap.put(newUser.id, oldValue);
            }

            // Changing a users store
            if(oldValue != null && newValue != null && oldValue != newValue){
                deleteMap.put(newUser.id, oldValue);
                createMap.put(newUser.id, newValue);
            }            


            System.debug(lprefix + ' delete Map :' + deleteMap);
            System.debug(lprefix + ' create Map :' + createMap);
            System.debug(lprefix + ' delete Map size:' + deleteMap.size());
            System.debug(lprefix + ' create Map size:' + createMap.size());                                   
        }

        if(deleteMap.size() > 0 || createMap.size() > 0){
            processUsers = true;
        }
        System.debug(lprefix + ' filterToUpdateRecords - END');
        return processUsers;
    }

    // update user acces process
    public static void updateUserAccess(Map<Id, User> oldMap, Map<Id, User> newMap){
        System.debug(lprefix + ' updateUserAccess - START');
        getData();
        processCreates();
        processDeletes();
        completeDML();
        System.debug(lprefix + ' updateUserAccess - END');
    }

    public static void getData(){
        System.debug(lprefix + ' getData - Start');
        for (String value: deleteMap.values()) {
            allStoresIds.add(value);
        }

        for (String value: createMap.values()) {
            allStoresIds.add(value);
        }
        System.debug(lprefix + ' allStoreIds: ' +allStoresIds);

        //get all the service territories that have a match on SAP id or Store Id
        matchStoreList =   [SELECT 
                            id,
                            Site_Account__r.SAP_STORE_ID__c,
                            Site_Account__r.Store_ID__c,
                            IsActive
                            FROM ServiceTerritory 
                            WHERE (Site_Account__r.SAP_STORE_ID__c IN :allStoresIds 
                            OR Site_Account__r.Store_ID__c IN :allStoresIds) 
                            AND IsActive = true];

        System.debug('matched stores size:' +matchStoreList.size());                        
        System.debug(matchStoreList);         

        // loop through all the stores and put them in the correct map to be used to lookup against
        for(ServiceTerritory territory :matchStoreList){
            System.debug('SAP Id: '+territory.Site_Account__r.SAP_STORE_ID__c + 'Store Id: '+territory.Site_Account__r.Store_ID__c);
            allStoresSalesforceIds.add(territory.id);
            if(territory.Site_Account__r.SAP_STORE_ID__c != null){
                sapIdMap.put(territory.Site_Account__r.SAP_STORE_ID__c, territory.id);                
            }
            if(territory.Site_Account__r.Store_ID__c != null){
                storeIdMap.put(territory.Site_Account__r.Store_ID__c, territory.id);
            }

            System.debug(sapIdMap);
            System.debug(storeIdMap);
        }

        // find any existing shared stores for the users impacted
        existingSharedStoresList = [SELECT
                                    id, 
                                    UserOrGroupId, 
                                    UserOrGroup.Name, 
                                    ParentId,  
                                    AccessLevel, 
                                    RowCause 
                                    FROM ServiceTerritoryShare WHERE (ParentId IN :allStoresSalesforceIds OR UserOrGroupId IN :userUpdateSet) AND RowCause = :SHARE_REASON];


        System.debug(lprefix + ' getData - END');
    }

    // Handles the creation of share records
    public static void processCreates(){
        System.debug(lprefix + ' processCreates - Start');
        for(id key: createMap.keySet()){

            // Matches against SAP Id first then checks legacy id
            id territoryId = sapIdMap.get(createMap.get(key));
            if(territoryId == null){
                territoryId = storeIdMap.get(createMap.get(key));
            }

            // Creates the share records and adds it to the share list
            if(territoryId != null){
                ServiceTerritoryShare newShare = new ServiceTerritoryShare();
                newShare.UserOrGroupId = key;
                newShare.RowCause = SHARE_REASON;
                newShare.ParentId = territoryId;
                newShare.AccessLevel = SHARE_ACCESS;

                newSharedStoresList.add(newShare);
            }            

            System.debug('key: ' + key + '  Value: ' + createMap.get(key));
        }
        System.debug(lprefix + ' processCreates - END');
    }

    // Process the delete records
    public static void processDeletes(){

        System.debug(lprefix + ' processDeletes - Start');
        for(id key: deleteMap.keySet()){
            
            for(ServiceTerritoryShare shareRecord: existingSharedStoresList){

                if(shareRecord.UserOrGroupId == key){
                    deleteSharedStoresList.add(shareRecord);
                }

            }                      

            System.debug('key: ' + key + '  Value: ' + deleteMap.get(key));
        }
        System.debug(lprefix + ' processDeletes - END');

    }

    // complete the DML for the proccess
    public static void completeDML(){
        System.debug(lprefix + ' completeDML - START');
        System.debug('Insert List:' + newSharedStoresList);
        System.debug('Insert List Size:' + newSharedStoresList.size());
        Savepoint sp = Database.setSavepoint(); 
        System.debug('Delete List:' + deleteSharedStoresList);        
        System.debug('Delete List Size:' + deleteSharedStoresList.size());
        try {

            // deletes records if at least 1 is needed
            if(deleteSharedStoresList.size() > 0){
                System.debug(lprefix + ' before delete - START');
                delete deleteSharedStoresList;
                System.debug(lprefix + ' after delete - End');
            }

            // creates new share records if at least 1 is needed. This is done asyc with a queueable class
            if(newSharedStoresList.size() > 0){
                System.debug(lprefix + ' before Appt_InsertShareRecordQueueable - START');
                System.enqueueJob(new Appt_InsertShareRecordQueueable(newSharedStoresList));   
                System.debug(lprefix + ' after Appt_InsertShareRecordQueueable - End');            
            }    
            
        } catch (Exception e) {
            Database.rollback( sp );
            System.debug(lprefix + ' DML Exception: ' + e.getMessage());
        }
        
        System.debug(lprefix + ' completeDML - END');
    }
}