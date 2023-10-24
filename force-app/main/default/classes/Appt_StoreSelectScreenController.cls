public without sharing class Appt_StoreSelectScreenController {

    public static string LPREFIX = 'Appt_StoreSelectScreenController :';
	//Addedd for SO-41
    public static Logger logInstance = Logger.getInstance();
    // method to create a new user favorite 
    @AuraEnabled
    public static Boolean createUserFavorite(string serviceTerritoryId) {
        Boolean success = false;
        system.debug('Start createUserFavorite: TerritoryId' + serviceTerritoryId); 

        Integer tryCount = 0;

        List<Appt_EntryScreenStore> returnStores = new List<Appt_EntryScreenStore>();
        id currentUserId = UserInfo.getUserId();
        System.debug('User Id '+currentUserId);

        System.debug(currentUserId);       

        Appt_User_Favorite__c newFav = new Appt_User_Favorite__c();
        newFav.User__c = currentUserId;
        newFav.Service_Territory__c = serviceTerritoryId;

        // tries 20 times to insert the record. This is becaue it is possible to have a record locking error on this transaction
        while(tryCount < 20){
            try {
                tryCount += 1;
                insert newFav; 
                success =  true; 
                tryCount = 20;
            } catch (Exception e) {               
                System.debug('try count: ' + tryCount + ' Exception' + e.getMessage());
                // SO-41 START:  Added logInstance 
                String errDetails = 'Cause: '+ e.getCause() +'\n';
                errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
                errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
                errDetails = errDetails + 'Message: '+ e.getMessage();
                logInstance.Log(LPREFIX, Appt_StoreSelectScreenController.class.getName(), errDetails); // SO-41 END
            }
        }              
        
        system.debug('End createUserFavorite: success' + success);      
        return success;
    }

    // method to remove a new user favorite 
    @AuraEnabled
    public static Boolean removeUserFavorite(string serviceTerritoryId) {
        system.debug('Start removeUserFavorite: TerritoryId' + serviceTerritoryId); 
        Boolean success = false;
        Integer tryCount = 0;
        
        
        id currentUserId = UserInfo.getUserId();

        List<Appt_User_Favorite__c> deleteFavoriteList = [SELECT 
                                            id,
                                            User__c, 
                                            Service_Territory__c 
                                            FROM Appt_User_Favorite__c 
                                            WHERE User__c = :currentUserId 
                                            AND Service_Territory__c = :serviceTerritoryId];

        if(deleteFavoriteList.size() > 0){
            // tries 20 times to delete the record. This is becaue it is possible to have a record locking error on this transaction
            while(tryCount < 20){
                try {
                    tryCount += 1;
                    delete deleteFavoriteList;  
                    success =  true; 
                    tryCount = 20;
                } catch (Exception e) {               
                    System.debug('try count: ' + tryCount + ' Exception' + e.getMessage());
                    // SO-41 START:  Added logInstance 
                    String errDetails = 'Cause: '+ e.getCause() +'\n';
                    errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
                    errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
                    errDetails = errDetails + 'Message: '+ e.getMessage();
                    logInstance.Log(LPREFIX, Appt_StoreSelectScreenController.class.getName(), errDetails); // SO-41 END
                }
            }  
        }       
        system.debug('End removeUserFavorite: success' + success); 
        return success;           
    }

    // used to get all user favorites
    public static List<Appt_User_Favorite__c> getFavorites(id currentUserId){
        return [SELECT id, Service_Territory__c, User__c FROM Appt_User_Favorite__c WHERE User__c = :currentUserId];
    }

}