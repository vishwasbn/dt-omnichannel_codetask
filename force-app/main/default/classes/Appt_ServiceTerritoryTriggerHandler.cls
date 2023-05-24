public without sharing class Appt_ServiceTerritoryTriggerHandler {
    public static String lprefix = 'LOG_ServiceTerritoryChangeOwner:';
    public static Map<String, id> sapIdMap =  new Map<String, id>();
    public static Map<String, id> storeIdMap =  new Map<String, id>();
    public static final String SHARE_REASON = 'Manual';
    public static final String SHARE_ACCESS = 'Read';


    public static void handle(Map<Id, ServiceTerritory> oldMap, Map<Id, ServiceTerritory> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Appt ServiceTerritoryTriggerHandler Handler - START');
       
        
        switch on triggerEvent 
        {
            when AFTER_UPDATE {    
                List<User> updateUsers = filterToUpdateRecords(oldMap,newMap);
                System.debug( lprefix + 'filterToUpdateRecords: ' + updateUsers);
                if(updateUsers.size() > 0){
                    updateUserAccess(updateUsers);
                }
            }   
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + ' Appt ServiceTerritoryTriggerHandler Handler - END');
    }

    public static List<User> filterToUpdateRecords(Map<Id, ServiceTerritory> oldMap, Map<Id, ServiceTerritory> newMap){
        List<User> returnUsers = new List<User>();        
        set<String> newOwnerAssignmentSet = new set<String>(); 
        set<id> territorySet = new set<id>(); 
        
        for (ServiceTerritory territory: newMap.values()) {
                      
            id oldValue = oldMap.get(territory.id).OwnerId;
            id newValue = territory.OwnerId;

            System.debug(lprefix + ' old value:' + oldValue);
            System.debug(lprefix + ' new value:' + newValue);

            if(oldValue != newValue){
                territorySet.add(territory.id);
            }           
        } 
        System.debug(lprefix + ' territory set:' + territorySet);
        if(territorySet.size()> 0){
            List<ServiceTerritory> territoryList = [SELECT 
                                                    id, 
                                                    Site_Account__r.Store_ID__c, 
                                                    Site_Account__r.SAP_STORE_ID__c 
                                                    FROM ServiceTerritory 
                                                    WHERE id IN :territorySet];

            System.debug(lprefix + ' territory List:' + territoryList);
            for(ServiceTerritory assignment :territoryList){
                if(assignment.Site_Account__r.Store_ID__c != null || assignment.Site_Account__r.Store_ID__c != ''){
                    newOwnerAssignmentSet.add(assignment.Site_Account__r.Store_ID__c);
                    sapIdMap.put(assignment.Site_Account__r.SAP_STORE_ID__c, assignment.id); 
                }
                if(assignment.Site_Account__r.SAP_STORE_ID__c != null || assignment.Site_Account__r.SAP_STORE_ID__c != ''){
                    newOwnerAssignmentSet.add(assignment.Site_Account__r.SAP_STORE_ID__c);
                    storeIdMap.put(assignment.Site_Account__r.Store_ID__c, assignment.id);
                }
                
            }
            System.debug(lprefix + ' New Owner Assignment Set:' + newOwnerAssignmentSet);
            
            returnUsers = [SELECT id, User_Store_Id__c FROM User WHERE User_Store_Id__c IN :newOwnerAssignmentSet];
        }
        return returnUsers;
    }

    public static void updateUserAccess(List<User> usersToUpdate){
        System.debug(lprefix + ' updateUserAccess - START');
        System.debug(lprefix + ' usersToUpdate ' +usersToUpdate);

        List<ServiceTerritoryShare> newSharedStoresList = new List<ServiceTerritoryShare>();

        for(User u : usersToUpdate){

            id territoryId = sapIdMap.get(u.User_Store_Id__c);
            if(territoryId == null){
                territoryId = storeIdMap.get(u.User_Store_Id__c);
            }

            if(territoryId != null){
                ServiceTerritoryShare newShare = new ServiceTerritoryShare();
                newShare.UserOrGroupId = u.id;
                newShare.RowCause = SHARE_REASON;
                newShare.ParentId = territoryId;
                newShare.AccessLevel = SHARE_ACCESS;
                newSharedStoresList.add(newShare);
            }                        
        }
        System.debug(lprefix + ' newSharedStoresList size: ' + newSharedStoresList.size());
        System.debug(lprefix + ' newSharedStoresList: ' + newSharedStoresList);
        try {
            if(newSharedStoresList.size() > 0){
                insert newSharedStoresList;
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }        
        
        
        System.debug(lprefix + ' updateUserAccess - END');
    }
}