/* 
    This is the main controller used as the primary entry point to salesforce for the 
    ApptStoreCapacityConfigMain LWC

    Created Date: 11-30-2021
    Created By: Samuel Chapin - apps associates
*/
public with sharing class Appt_StoreCapacityConfigMainController {

    // SO-41
    public static String LPREFIX = 'Appt_StoreCapacityConfigMainController :';
    public static Logger logInstance = Logger.getInstance();
    // Method used to get the list of stores that the user has access to
    @AuraEnabled
    public static string getStores(String searchString){
        List<Appt_EntryScreenStore> stores = new List<Appt_EntryScreenStore>();
        try {
            stores = getStoreData(searchString);
        } catch (Exception e) {
            System.debug(e.getMessage());
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_StoreCapacityConfigMainController.class.getName(), errDetails); // SO-41 END
        }
        
        String results = JSON.serialize(stores);
        return results;
    }

    // Method used to get the stores current configurations for a particular day of the week
    @AuraEnabled
    public static string getStoreConfig(String serviceTerritory, String selectedDay){
        Appt_StoreConfigs storesConfig = new Appt_StoreConfigs();

        try {
            Appt_StoreConfigs newConfig = new Appt_StoreConfigs(serviceTerritory, selectedDay);
            storesConfig = newConfig;
        } catch (Exception e) {
            System.debug(e.getMessage());
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_StoreCapacityConfigMainController.class.getName(), errDetails); // SO-41 END

            storesConfig.success = false;
            storesConfig.errorMessage = e.getMessage();     
        }

        String results = JSON.serialize(storesConfig);
        return results;
    }

    // Method used to udate the stores configurations based on updates in the UI
    @AuraEnabled
    public static string updateStoreConfig(String updateConfigsObject){
        UpdateStoreResponse updateResults = new UpdateStoreResponse(true,'');  
        try {
            System.debug('LWC Object' + updateConfigsObject);
            Appt_UpdateStoreConfig storesConfig = new Appt_UpdateStoreConfig();
            storesConfig = (Appt_UpdateStoreConfig) JSON.deserialize(updateConfigsObject, Appt_UpdateStoreConfig.class);
            updateResults.success = Appt_StoreConfigUpdateProcess.updateStoreProcess(storesConfig);
            System.debug(storesConfig);
            System.debug(storesConfig.selectedDays[0]);
            System.debug(storesConfig.ApptTimeSlotCapacities[0]);
        } catch (Exception e) {
            System.debug(e);
            // SO-41 START:  Added logInstance 
            String errDetails = 'Cause: '+ e.getCause() +'\n';
            errDetails = errDetails + 'LineNumber: '+ e.getLineNumber() +'\n';
            errDetails = errDetails + 'Stack trace: '+ e.getStackTraceString()+ '\n';
            errDetails = errDetails + 'Message: '+ e.getMessage();
            logInstance.Log(LPREFIX, Appt_StoreCapacityConfigMainController.class.getName(), errDetails); // SO-41 END
            
            updateResults.success = false;
            updateResults.errorMessage = e.getMessage();
        }
                      
        String results = JSON.serialize(updateResults);
        return results;
    }
 
    // Accepts a service territoy Id and returns a list of Appt_EntryScreenStore objects
    public static List<Appt_EntryScreenStore> getStoreData(String searchParameter){
        System.debug('Start getStoreData');

        // setup default values
        List<Appt_EntryScreenStore> returnStores = new List<Appt_EntryScreenStore>();
        id currentUserId = UserInfo.getUserId();
        System.debug('User Id '+currentUserId);

        System.debug(currentUserId);
        // get user favorites
        List<Appt_User_Favorite__c> favs = Appt_StoreSelectScreenController.getFavorites(currentUserId);
        System.debug('Favorites '+favs);
        Map<Id,Boolean> favsMap = new Map<Id,Boolean>();
        for(Appt_User_Favorite__c fav: favs){
            favsMap.put(fav.Service_Territory__c,true);
        }
        System.debug('Favorites Map '+favsMap);
        List<ServiceTerritory> storeInfoList = [SELECT  
                                            id, 
                                            Site_Account__r.Store_ID__c,  
                                            Site_Account__r.SAP_STORE_ID__c, 
                                            Site_Account__r.ShippingStreet, 
                                            Site_Account__r.ShippingCity, 
                                            Site_Account__r.ShippingState, 
                                            Site_Account__r.ShippingPostalCode 
                                            FROM ServiceTerritory 
                                            WHERE IsActive = true
                                            ORDER BY Site_Account__r.Store_ID__c];

        

        for(ServiceTerritory store: storeInfoList){
            Appt_EntryScreenStore newStore = new Appt_EntryScreenStore( store.id, 
                                                                        store.Site_Account__r.Store_ID__c,
                                                                        store.Site_Account__r.SAP_STORE_ID__c, 
                                                                        store.Site_Account__r.ShippingStreet, 
                                                                        store.Site_Account__r.ShippingCity, 
                                                                        store.Site_Account__r.ShippingState, 
                                                                        store.Site_Account__r.ShippingPostalCode,
                                                                        favsMap);
            returnStores.add(newStore);
                   
        }
        System.debug('Store List Length' + returnStores.size());
        System.debug('End getStoreData');
        return returnStores;        
    } 
    // Inner class for response object
    public class UpdateStoreResponse{
        public Boolean success;
        public String errorMessage;

        public UpdateStoreResponse(Boolean success, String errorMessage) {
            this.success = success;
            this.errorMessage = errorMessage;
        }

    }
}