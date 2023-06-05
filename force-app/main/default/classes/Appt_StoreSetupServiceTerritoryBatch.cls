/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/26/22
 * @description Batch Class used to create Service Resources, Service Territories, Service Territory Members, and Appt Time Slot Capacities during the Automated Store Setup Process
 */

public without sharing class Appt_StoreSetupServiceTerritoryBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents {
    private final String LOG_CLASS_NAME = 'Appt_StoreSetupServiceTerritoryBatch';

    private List<String> selectedStoreSetupImportIds;

    //Maps passed in from Appt_StoreSetupUserBatch to assist with setting the Front/Back Room User Lookup fields on the related Store Setup Import record
    private Map<String, String> storeSetupImportIdsToFrontUserIdsMap;
    private Map<String, String> storeSetupImportIdsToBackUserIdsMap;

    //Map passed in from Appt_StoreSetupUserBatch to assist with tracking Errors during Front/Back User Setup (if any occur) so they can be set on the User Creation Message field on the related Store Setup Import record
    private Map<String, String> storeSetupImportIdsToUserErrorsMap;

    private String currentUserEmail;

    //Variables to track a List of Ids for new Service Territories and processed Store Setup Import Ids so they can be passed into Appt_GenerateCleanupApptTimeSlotsBatch
    private List<String> newServiceTerritoryIds;
    private List<String> processedStoreSetupImportIds;

    public Appt_StoreSetupServiceTerritoryBatch(List<String> selectedStoreImportIds, Map<String, String> storeSetupImportIdsToFrontUserIdsMap, Map<String, String> storeSetupImportIdsToBackUserIdsMap, Map<String, String> storeSetupImportIdsToUserErrorsMap, String currentUserEmail) {
        this.selectedStoreSetupImportIds = selectedStoreImportIds;
        this.storeSetupImportIdsToFrontUserIdsMap = storeSetupImportIdsToFrontUserIdsMap;
        this.storeSetupImportIdsToBackUserIdsMap = storeSetupImportIdsToBackUserIdsMap;
        this.storeSetupImportIdsToUserErrorsMap = storeSetupImportIdsToUserErrorsMap;
        this.currentUserEmail = currentUserEmail;
        newServiceTerritoryIds = new List<String>();
        processedStoreSetupImportIds = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!selectedStoreSetupImportIds.isEmpty()) {
            //If Store Setup Imports were selected, then query for those records only
            return Database.getQueryLocator([SELECT Back_Appointment_Work_Type__c, Back_Room_Service_Resource__c, Back_Room_User__c, Back_Time_Slot_Configuration__c, Front_Back_Room_Default_Capacity_Group__c, Front_Back_Room_Resource_Type__c, Front_Appointment_Work_Type__c, Front_Room_Service_Resource__c, Front_Room_User__c, Front_Time_Slot_Configuration__c, Operating_Hours__c, POS_Terminal_User__c, Scheduling_Policy__c, Service_Territory__c, Store_Creation_Message__c, Store_Creation_Status__c, Store_ID__c, Store_Is_Active__c, User_Creation_Message__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id IN :selectedStoreSetupImportIds]);
        } else {
            //If no Store Setup Imports were selected, then query for all records with a User Creation Status of "Ready"
            return Database.getQueryLocator([SELECT Back_Appointment_Work_Type__c, Back_Room_Service_Resource__c, Back_Room_User__c, Back_Time_Slot_Configuration__c, Front_Back_Room_Default_Capacity_Group__c, Front_Back_Room_Resource_Type__c, Front_Appointment_Work_Type__c, Front_Room_Service_Resource__c, Front_Room_User__c, Front_Time_Slot_Configuration__c, Operating_Hours__c, POS_Terminal_User__c, Scheduling_Policy__c, Service_Territory__c, Store_Creation_Message__c, Store_Creation_Status__c, Store_ID__c, Store_Is_Active__c, User_Creation_Message__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE User_Creation_Status__c = :Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY]);
        }
    }

    public void execute(Database.BatchableContext bc, List<Store_Setup_Import__c> storeSetupImports) {
        //Initialize Logger instance
        Logger logInstance = Logger.getInstance(true);

        //Setup StoreSetupImportConfiguration to check for any errors during User Creation and also setup Maps to assist in processing the given Store Setup Imports
        StoreSetupImportConfiguration storeSetupImportConfig = new StoreSetupImportConfiguration(storeSetupImports, storeSetupImportIdsToUserErrorsMap, storeSetupImportIdsToFrontUserIdsMap, storeSetupImportIdsToBackUserIdsMap);

        //Create/Process Service Resources
        ServiceResourceConfiguration serviceResourceConfig = new ServiceResourceConfiguration(storeSetupImportConfig);
        List<ServiceResource> serviceResourcesToInsert = serviceResourceConfig.getServiceResourcesToInsert(storeSetupImportConfig);
        processServiceResources(serviceResourcesToInsert, serviceResourceConfig, storeSetupImportConfig, logInstance);

        //Create/Process Service Territories
        ServiceTerritoryConfiguration serviceTerritoryConfig = new ServiceTerritoryConfiguration(storeSetupImportConfig);
        List<ServiceTerritory> serviceTerritoriesToInsert = serviceTerritoryConfig.getServiceTerritoriesToInsert(storeSetupImportConfig);
        processServiceTerritories(serviceTerritoriesToInsert, serviceTerritoryConfig, storeSetupImportConfig, logInstance);

        //Create/Process Service Territory Members
        ServiceTerritoryMemberConfiguration serviceTerritoryMemberConfig = new ServiceTerritoryMemberConfiguration(serviceResourceConfig, serviceTerritoryConfig);
        List<ServiceTerritoryMember> serviceTerritoryMembersToInsert = serviceTerritoryMemberConfig.getServiceTerritoryMembersToInsert(storeSetupImportConfig);
        processServiceTerritoryMembers(serviceTerritoryMembersToInsert, serviceTerritoryConfig, storeSetupImportConfig, logInstance);

        //Create/Process Appt Time Slot Capacities
        ApptTimeSlotCapacityConfiguration apptTimeSlotCapacityConfig = new ApptTimeSlotCapacityConfiguration(serviceTerritoryConfig, storeSetupImportConfig);
        List<Appt_Time_Slot_Capacity__c> apptTimeSlotCapacitiesToInsert = apptTimeSlotCapacityConfig.getApptTimeSlotCapacitiesToInsert(storeSetupImportConfig, serviceTerritoryConfig);
        processApptTimeSlotCapacities(apptTimeSlotCapacitiesToInsert, serviceTerritoryConfig, storeSetupImportConfig, logInstance);

        //Process Store Setup Imports and check if they can be marked as Complete
        processStoreSetupImports(storeSetupImportConfig, logInstance);

        //Insert Logs, if any were created
        logInstance.finalize();
    }

    public void finish(Database.BatchableContext bc) {
        //Upon completion of this Batch, start the Appt_GenerateCleanupApptTimeSlotsBatch process to create the necessary Appt Time Slots
        String generateCleanupApptTimeSlotsBatchSizeString = Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_GENERATE_CLEANUP_APPT_TIME_SLOTS_BATCH_SIZE);
        Integer generateCleanupApptTimeSlotsBatchSize = String.isNotBlank(generateCleanupApptTimeSlotsBatchSizeString) ? Integer.valueOf(generateCleanupApptTimeSlotsBatchSizeString) : 3;
        Appt_GenerateCleanupApptTimeSlotsBatch generateCleanupApptTimeSlotsBatch = new Appt_GenerateCleanupApptTimeSlotsBatch(newServiceTerritoryIds, processedStoreSetupImportIds, currentUserEmail);
        Database.executeBatch(generateCleanupApptTimeSlotsBatch, generateCleanupApptTimeSlotsBatchSize);
    }

    private void processServiceResources(List<ServiceResource> serviceResourcesToInsert, ServiceResourceConfiguration serviceResourceConfig, StoreSetupImportConfiguration storeSetupImportConfig, Logger logInstance) {
        if (!serviceResourcesToInsert.isEmpty()) {
            //If there are Service Resources to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(serviceResourcesToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'ServiceResource', saveResults);
        }

        //Create a List of Service Resources to process that includes the newly inserted Service Resources as well as any existing Service Resources related to the given Store Setup Imports
        List<ServiceResource> serviceResourcesToProcess = new List<ServiceResource>(serviceResourcesToInsert);
        serviceResourcesToProcess.addAll(serviceResourceConfig.existingFrontServiceResourceIdsToRecordsMap.values());
        serviceResourcesToProcess.addAll(serviceResourceConfig.existingBackServiceResourceIdsToRecordsMap.values());

        //Track Front and Back Service Resources on Store Setup Imports
        for (ServiceResource sr : serviceResourcesToProcess) {
            if (sr.Id != null) {
                if (storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.containsKey(sr.RelatedRecordId) && storeSetupImportConfig.storeSetupImportIdsToRecordsMap.containsKey(storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.get(sr.RelatedRecordId))) {
                    storeSetupImportConfig.storeSetupImportIdsToRecordsMap.get(storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.get(sr.RelatedRecordId)).Front_Room_Service_Resource__c = sr.Id;
                    serviceResourceConfig.serviceResourceIds.add(sr.Id);
                } else if (storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.containsKey(sr.RelatedRecordId) && storeSetupImportConfig.storeSetupImportIdsToRecordsMap.containsKey(storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.get(sr.RelatedRecordId))) {
                    storeSetupImportConfig.storeSetupImportIdsToRecordsMap.get(storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.get(sr.RelatedRecordId)).Back_Room_Service_Resource__c = sr.Id;
                    serviceResourceConfig.serviceResourceIds.add(sr.Id);
                } else {
                    logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Service Resource ' + sr.Name + ' (' + sr.Id + ') could not be matched to an existing Store Setup Import record.');
                }
            } else {
                logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Service Resource ' + sr.Name + ' could not be created. Please check the Logs for additional details.');
            }
        }
    }

    private void processServiceTerritories(List<ServiceTerritory> serviceTerritoriesToInsert, ServiceTerritoryConfiguration serviceTerritoryConfig, StoreSetupImportConfiguration storeSetupImportConfig, Logger logInstance) {
        if (!serviceTerritoriesToInsert.isEmpty()) {
            //If there are Service Territories to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(serviceTerritoriesToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'ServiceTerritory', saveResults);
        }

        //Create a List of Service Territories to process that includes the newly inserted Service Territories as well as any existing Service Territories related to the given Store Setup Imports
        List<ServiceTerritory> serviceTerritoriesToProcess = new List<ServiceTerritory>(serviceTerritoriesToInsert);
        serviceTerritoriesToProcess.addAll(serviceTerritoryConfig.existingServiceTerritoryNamesToRecordsMap.values());

        //Track Service Territory on Store Setup Import records
        for (ServiceTerritory st : serviceTerritoriesToProcess) {
            if (st.Id != null) {
                if (storeSetupImportConfig.storeSetupImportNamesToIdsMap.containsKey(st.Name) && storeSetupImportConfig.storeSetupImportIdsToRecordsMap.containsKey(storeSetupImportConfig.storeSetupImportNamesToIdsMap.get(st.Name))) {
                    String storeSetupImportId = storeSetupImportConfig.storeSetupImportNamesToIdsMap.get(st.Name);
                    storeSetupImportConfig.storeSetupImportIdsToRecordsMap.get(storeSetupImportId).Service_Territory__c = st.Id;
                    serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.put(st.Id, storeSetupImportId);
                } else {
                    logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Service Territory ' + st.Name + ' (' + st.Id + ') could not be matched to an existing Store Setup Import record.');
                }
            } else {
                logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Service Territory ' + st.Name + ' could not be created. Please check the Logs for additional details.');
            }
        }
    }

    private void processServiceTerritoryMembers(List<ServiceTerritoryMember> serviceTerritoryMembersToInsert, ServiceTerritoryConfiguration serviceTerritoryConfig, StoreSetupImportConfiguration storeSetupImportConfig, Logger logInstance) {
        if (!serviceTerritoryMembersToInsert.isEmpty()) {
            //If there are Service Territory Members to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(serviceTerritoryMembersToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'ServiceTerritoryMember', saveResults);

            //Loop through inserted Service Territory Members to check if any failed, if they did then set an Error Status and Message on the Store Setup Import record
            for (ServiceTerritoryMember stm : serviceTerritoryMembersToInsert) {
                if (stm.Id == null) {
                    if (serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.containsKey(stm.ServiceTerritoryId) && storeSetupImportConfig.storeSetupImportIdsToRecordsMap.containsKey(serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.get(stm.ServiceTerritoryId))) {
                        Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImportConfig.storeSetupImportIdsToRecordsMap.get(serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.get(stm.ServiceTerritoryId)), 'Service Territory Member with Service Resource Id (' + stm.ServiceResourceId + ') was not found for this Store Setup Import. Please check the Logs for additional details.');
                    } else {
                        logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Service Territory Member with Service Resource Id (' + stm.ServiceResourceId + ') and Service Territory Id (' + stm.ServiceTerritoryId +') could not be created. Please check the Logs for additional details.');
                    }
                }
            }
        }
    }

    private void processApptTimeSlotCapacities(List<Appt_Time_Slot_Capacity__c> apptTimeSlotCapacitiesToInsert, ServiceTerritoryConfiguration serviceTerritoryConfig, StoreSetupImportConfiguration storeSetupImportConfig, Logger logInstance) {
        if (!apptTimeSlotCapacitiesToInsert.isEmpty()) {
            //If there are Appt Time Slot Capacities to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(apptTimeSlotCapacitiesToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'Appt_Time_Slot_Capacity__c', saveResults);

            //Loop through inserted Appt Time Slot Capacities to check if any failed, if they did then set an Error Status and Message on the Store Setup Import record
            for (Appt_Time_Slot_Capacity__c atsc : apptTimeSlotCapacitiesToInsert) {
                if (atsc.Id == null) {
                    if (serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.containsKey(atsc.Service_Territory__c) && storeSetupImportConfig.storeSetupImportIdsToRecordsMap.containsKey(serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.get(atsc.Service_Territory__c))) {
                        Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImportConfig.storeSetupImportIdsToRecordsMap.get(serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.get(atsc.Service_Territory__c)), 'Appt Time Slot Capacity for ' + atsc.Day_of_Week__c + ' ' + atsc.Start_Time__c + ' - ' + atsc.End_Time__c +  ' was not found for this Store Setup Import. Please check the Logs for additional details.');
                    } else {
                        logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'Appt Time Slot Capacity for ' + atsc.Day_of_Week__c + ' ' + atsc.Start_Time__c + ' - ' + atsc.End_Time__c +  ' with Service Territory Id (' + atsc.Service_Territory__c +') could not be created. Please check the Logs for additional details.');
                    }
                }
            }
        }
    }

    private void processStoreSetupImports(StoreSetupImportConfiguration storeSetupImportConfig, Logger logInstance) {
        //Loop through Store Setup Import records that were processed in this Batch to track their Ids and also check if they can be marked as Complete
        for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
            processedStoreSetupImportIds.add(storeSetupImport.Id);
            if (String.isBlank(storeSetupImport.User_Creation_Message__c) && String.isBlank(storeSetupImport.Store_Creation_Message__c) && String.isNotBlank(storeSetupImport.Service_Territory__c)) {
                storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
                storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
                storeSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY;
                storeSetupImport.Time_Slot_Creation_Message__c = '';
                newServiceTerritoryIds.add(storeSetupImport.Service_Territory__c);
            }
        }

        //Update Store Setup Import records to save any values that were added and track any errors
        List<Database.SaveResult> saveResults = Database.update(storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values(), false);
        logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'Store_Setup_Import__c', saveResults);
    }

    //Wrapper class used to assist with processing the given Store Setup Imports
    public class StoreSetupImportConfiguration {
        private Map<String, Store_Setup_Import__c> storeSetupImportIdsToRecordsMap;
        private Map<String, String> storeSetupImportNamesToIdsMap;
        private Map<String, String> frontUserIdToStoreSetupImportIdMap;
        private Map<String, String> backUserIdToStoreSetupImportIdMap;
        private Set<String> apptTimeSlotCapacityDefaultGroupNames;

        public StoreSetupImportConfiguration(List<Store_Setup_Import__c> storeSetupImports, Map<String, String> storeSetupImportIdsToUserErrorsMap, Map<String, String> storeSetupImportIdsToFrontUserIdsMap, Map<String, String> storeSetupImportIdsToBackUserIdsMap) {
            checkForUserCreationErrorsAndSetupMaps(storeSetupImports, storeSetupImportIdsToUserErrorsMap, storeSetupImportIdsToFrontUserIdsMap, storeSetupImportIdsToBackUserIdsMap);
            setupApptTimeSlotCapacityDefaultGroupNames(storeSetupImports);
        }

        private void checkForUserCreationErrorsAndSetupMaps(List<Store_Setup_Import__c> storeSetupImports, Map<String, String> storeSetupImportIdsToUserErrorsMap, Map<String, String> storeSetupImportIdsToFrontUserIdsMap, Map<String, String> storeSetupImportIdsToBackUserIdsMap) {
            //Build Maps of Store Setup Imports to be processed and Maps of Front/Back Users to their associated Store Setup Import
            storeSetupImportIdsToRecordsMap = new Map<String, Store_Setup_Import__c>();
            storeSetupImportNamesToIdsMap = new Map<String, String>();
            frontUserIdToStoreSetupImportIdMap = new Map<String, String>();
            backUserIdToStoreSetupImportIdMap = new Map<String, String>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImports) {
                //Reset Statuses and Messages prior to checking for Errors (in case the Store Setup Import is being reprocessed)
                storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY;
                storeSetupImport.User_Creation_Message__c = '';
                storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_NOT_READY;
                storeSetupImport.Store_Creation_Message__c = '';
                storeSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_NOT_READY;
                storeSetupImport.Time_Slot_Creation_Message__c = '';

                if (storeSetupImportIdsToUserErrorsMap.containsKey(storeSetupImport.Id)) {
                    //If the Store Setup Import had an error passed in from the Appt_StoreSetupUserBatch, then add it to the record
                    Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImport, storeSetupImportIdsToUserErrorsMap.get(storeSetupImport.Id));
                }

                //Check if the Store Setup Import had a Front User passed in from the Appt_StoreSetupUserBatch, if not then set an error on the Store Setup Import
                if (storeSetupImportIdsToFrontUserIdsMap.containsKey(storeSetupImport.Id)) {
                    storeSetupImport.Front_Room_User__c = storeSetupImportIdsToFrontUserIdsMap.get(storeSetupImport.Id);
                    frontUserIdToStoreSetupImportIdMap.put(storeSetupImport.Front_Room_User__c, storeSetupImport.Id);
                } else {
                    Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImport, 'Front Room User was not found for this Store Setup Import. Please check the Logs for additional details.');
                }

                //Check if the Store Setup Import had a Back User passed in from the Appt_StoreSetupUserBatch, if not then set an error on the Store Setup Import
                if (storeSetupImportIdsToBackUserIdsMap.containsKey(storeSetupImport.Id)) {
                    storeSetupImport.Back_Room_User__c = storeSetupImportIdsToBackUserIdsMap.get(storeSetupImport.Id);
                    backUserIdToStoreSetupImportIdMap.put(storeSetupImport.Back_Room_User__c, storeSetupImport.Id);
                } else {
                    Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImport, 'Back User was not found for this Store Setup Import. Please check the Logs for additional details.');
                }

                if (storeSetupImport.User_Creation_Status__c != Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR) {
                    //If the Store Setup Import did not have an error during User Creation/Processing, then mark that step as Complete and set Store Creation Status to Ready
                    storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
                    storeSetupImport.User_Creation_Message__c = '';
                    storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY;
                    storeSetupImport.Store_Creation_Message__c = '';
                }

                storeSetupImportIdsToRecordsMap.put(storeSetupImport.Id, storeSetupImport);
                storeSetupImportNamesToIdsMap.put(storeSetupImport.Store_ID__c, storeSetupImport.Id);
            }
        }

        private void setupApptTimeSlotCapacityDefaultGroupNames(List<Store_Setup_Import__c> storeSetupImports) {
            //Build Set of Appt Time Slot Capacity Default Group Names
            apptTimeSlotCapacityDefaultGroupNames = new Set<String>();
            for (Store_Setup_Import__c ssi : storeSetupImports) {
                apptTimeSlotCapacityDefaultGroupNames.add(ssi.Front_Back_Room_Default_Capacity_Group__c);
            }
        }
    }

    //Wrapper class used to assist with processing the given Store Setup Import's related Service Resources
    public class ServiceResourceConfiguration {
        private Map<String, ServiceResource> existingFrontServiceResourceIdsToRecordsMap;
        private Map<String, ServiceResource> existingBackServiceResourceIdsToRecordsMap;

        private Set<Id> serviceResourceIds;

        public ServiceResourceConfiguration(StoreSetupImportConfiguration storeSetupImportConfig) {
            setupExistingServiceResourceVariables(storeSetupImportConfig);
            serviceResourceIds = new Set<Id>();
        }

        private void setupExistingServiceResourceVariables(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build Maps of existing Front/Back Service Resources that will be used to ensure duplicate records are not attempted to be created
            existingFrontServiceResourceIdsToRecordsMap = new Map<String, ServiceResource>();
            existingBackServiceResourceIdsToRecordsMap = new Map<String, ServiceResource>();
            for (ServiceResource sr : [SELECT Id, Name, RelatedRecordId FROM ServiceResource WHERE (RelatedRecordId IN :storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.keySet() AND Type__c = :Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT) OR (RelatedRecordId IN :storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.keySet() AND Type__c = :Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK)]) {
                if (storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.containsKey(sr.RelatedRecordId)) {
                    existingFrontServiceResourceIdsToRecordsMap.put(sr.RelatedRecordId, sr);
                } else if (storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.containsKey(sr.RelatedRecordId)) {
                    existingBackServiceResourceIdsToRecordsMap.put(sr.RelatedRecordId, sr);
                }
            }
        }

        private ServiceResource setupServiceResource(Store_Setup_Import__c storeSetupImport, String userId, String userType) {
            //Create new Service Resource record with the necessary data
            ServiceResource sr = new ServiceResource();
            sr.Name = storeSetupImport.Store_ID__c + ' ' + userType;
            sr.RelatedRecordId = userId;
            sr.ResourceType = storeSetupImport.Front_Back_Room_Resource_Type__c;
            sr.Type__c = userType + ' Room';
            sr.IsActive = true;

            return sr;
        }

        private List<ServiceResource> getServiceResourcesToInsert(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build List of Service Resources that need to be inserted
            List<ServiceResource> serviceResourcesToInsert = new List<ServiceResource>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
                if (Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport)) {
                    //If error previously occurred on the Store Setup Import, then skip the record (it will need to be reprocessed)
                    continue;
                }

                String frontUserId = storeSetupImport.Front_Room_User__c;
                if (!existingFrontServiceResourceIdsToRecordsMap.containsKey(frontUserId)) {
                    //If Service Resource does not already exist for Front Room User, then setup their Service Resource
                    storeSetupImportConfig.frontUserIdToStoreSetupImportIdMap.put(frontUserId, storeSetupImport.Id);
                    serviceResourcesToInsert.add(setupServiceResource(storeSetupImport, frontUserId, 'Front'));
                }

                String backUserId = storeSetupImport.Back_Room_User__c;
                if (!existingBackServiceResourceIdsToRecordsMap.containsKey(backUserId)) {
                    //If Service Resource does not already exist for Back Room User, then setup their Service Resource
                    storeSetupImportConfig.backUserIdToStoreSetupImportIdMap.put(backUserId, storeSetupImport.Id);
                    serviceResourcesToInsert.add(setupServiceResource(storeSetupImport, backUserId, 'Back'));
                }
            }
            return serviceResourcesToInsert;
        }
    }

    //Wrapper class used to assist with processing the given Store Setup Import's related Service Territories
    public class ServiceTerritoryConfiguration {
        private Map<String, String> bucketCapacityOperatingHoursNamesToIdsMap;
        private Map<String, String> storeHoursOperatingHoursNamesToIdsMap;
        private Map<String, String> serviceTerritoryIdsToStoreImportSetupIdsMap;
        private Map<String, String> schedulingPolicyNamesToIdsMap;
        private Map<String, String> workTypeNamesToIdsMap;
        private Map<String, String> siteAccountStoreIDsToAccountIdsMap;
        private Map<String, String> posTerminalUserNamesToIdsMap;

        private Map<String, ServiceTerritory> existingServiceTerritoryNamesToRecordsMap;

        //Map<OperatingHoursId, Map<DayOfWeek, List<TimeSlot>>>
        private Map<String, Map<String, List<TimeSlot>>> bucketCapacityOperatingHoursTimeSlotsMap;

        //Map<OperatingHoursId, Map<DayOfWeek, List<TimeSlot>>>
        private Map<String, Map<String, List<TimeSlot>>> storeHoursOperatingHoursTimeSlotsMap;

        public ServiceTerritoryConfiguration(StoreSetupImportConfiguration storeSetupImportConfig) {
            setupOperatingHoursMaps();
            setupSchedulingPolicyMap();
            setupWorkTypeMap();
            setupSiteAccountAndPOSTerminalUserMaps(storeSetupImportConfig);
            setupExistingServiceTerritoryNamesToRecordsMap(storeSetupImportConfig);
            serviceTerritoryIdsToStoreImportSetupIdsMap = new Map<String, String>();
        }

        private void setupOperatingHoursMaps() {
            //Build Maps of "Bucket Hours" and "Store Hours" Operating Hours
            bucketCapacityOperatingHoursNamesToIdsMap = new Map<String, String>();
            bucketCapacityOperatingHoursTimeSlotsMap = new Map<String, Map<String, List<TimeSlot>>>();
            storeHoursOperatingHoursNamesToIdsMap = new Map<String, String>();
            storeHoursOperatingHoursTimeSlotsMap = new Map<String, Map<String, List<TimeSlot>>>();
            for (OperatingHours oh : [SELECT Id, Name, Type__c, (SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlots ORDER BY DayOfWeek, StartTime) FROM OperatingHours WHERE Type__c IN (:Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY, :Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS)]) {
                if (oh.Type__c.equalsIgnoreCase(Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS)) {
                    storeHoursOperatingHoursNamesToIdsMap.put(oh.Name, oh.Id);
                    storeHoursOperatingHoursTimeSlotsMap.put(oh.Id, new Map<String, List<TimeSlot>>());
                    for (TimeSlot ts : oh.TimeSlots) {
                        if (!storeHoursOperatingHoursTimeSlotsMap.get(oh.Id).containsKey(ts.DayOfWeek)) {
                            storeHoursOperatingHoursTimeSlotsMap.get(oh.Id).put(ts.DayOfWeek, new List<TimeSlot>());
                        }
                        storeHoursOperatingHoursTimeSlotsMap.get(oh.Id).get(ts.DayOfWeek).add(ts);
                    }
                } else if (oh.Type__c.equalsIgnoreCase(Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY)) {
                    bucketCapacityOperatingHoursNamesToIdsMap.put(oh.Name, oh.Id);
                    bucketCapacityOperatingHoursTimeSlotsMap.put(oh.Id, new Map<String, List<TimeSlot>>());
                    for (TimeSlot ts : oh.TimeSlots) {
                        if (!bucketCapacityOperatingHoursTimeSlotsMap.get(oh.Id).containsKey(ts.DayOfWeek)) {
                            bucketCapacityOperatingHoursTimeSlotsMap.get(oh.Id).put(ts.DayOfWeek, new List<TimeSlot>());
                        }
                        bucketCapacityOperatingHoursTimeSlotsMap.get(oh.Id).get(ts.DayOfWeek).add(ts);
                    }
                }
            }
        }

        private void setupSchedulingPolicyMap() {
            //Build Map of Scheduling Policies
            schedulingPolicyNamesToIdsMap = new Map<String, String>();
            for (FSL__Scheduling_Policy__c sp : [SELECT Id, Name FROM FSL__Scheduling_Policy__c]) {
                schedulingPolicyNamesToIdsMap.put(sp.Name, sp.Id);
            }
        }

        private void setupWorkTypeMap() {
            //Build Map of Work Types
            workTypeNamesToIdsMap = new Map<String, String>();
            for (WorkType wt : [SELECT Id, Name FROM WorkType]) {
                workTypeNamesToIdsMap.put(wt.Name, wt.Id);
            }
        }

        private void setupSiteAccountAndPOSTerminalUserMaps(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build Sets of Site Account Names and POS Terminal User Names
            Set<String> siteAccountStoreIDs = new Set<String>();
            Set<String> posTerminalUserNames = new Set<String>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
                siteAccountStoreIDs.add(storeSetupImport.Store_ID__c);
                if (String.isNotBlank(storeSetupImport.POS_Terminal_User__c)) {
                    posTerminalUserNames.add(storeSetupImport.POS_Terminal_User__c);
                } else {
                    posTerminalUserNames.add(storeSetupImport.Store_ID__c);
                }
            }

            //Build Map of Site Accounts
            siteAccountStoreIDsToAccountIdsMap = new Map<String, String>();
            for (Account a : [SELECT Id, Store_ID__c FROM Account WHERE Store_ID__c IN :siteAccountStoreIDs AND RecordType.Name = 'Site']) {
                siteAccountStoreIDsToAccountIdsMap.put(a.Store_ID__c, a.Id);
            }

            //Build Map of POS Terminal Users
            posTerminalUserNamesToIdsMap = new Map<String, String>();
            for (User u : [SELECT Id, Name FROM User WHERE Name IN :posTerminalUserNames AND Profile.Name = 'POS Store Terminal']) {
                posTerminalUserNamesToIdsMap.put(u.Name, u.Id);
            }
        }

        private void setupExistingServiceTerritoryNamesToRecordsMap(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build Map of existing Service Territories that will be used to ensure duplicate records are not attempted to be created
            existingServiceTerritoryNamesToRecordsMap = new Map<String, ServiceTerritory>();
            for (ServiceTerritory st : [SELECT Id, Name FROM ServiceTerritory WHERE Name IN :storeSetupImportConfig.storeSetupImportNamesToIdsMap.keySet()]) {
                existingServiceTerritoryNamesToRecordsMap.put(st.Name, st);
            }
        }

        private ServiceTerritory setupServiceTerritory(Store_Setup_Import__c storeSetupImport) {
            //Create new Service Territory record with the necessary data
            ServiceTerritory st = new ServiceTerritory();
            st.Name = storeSetupImport.Store_ID__c;
            st.IsActive = storeSetupImport.Store_Is_Active__c;

            //Check if a Scheduling Policy matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (schedulingPolicyNamesToIdsMap.containsKey(storeSetupImport.Scheduling_Policy__c)) {
                st.Scheduling_Policy__c = schedulingPolicyNamesToIdsMap.get(storeSetupImport.Scheduling_Policy__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The selected Scheduling Policy on this Store Setup Import could not be found.');
            }

            //Check if a Site Account matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (siteAccountStoreIDsToAccountIdsMap.containsKey(storeSetupImport.Store_ID__c)) {
                st.Site_Account__c = siteAccountStoreIDsToAccountIdsMap.get(storeSetupImport.Store_ID__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The selected Site Account on this Store Setup Import could not be found.');
            }

            //Check if a Bucket Capacity Operating Hours for the Front Time Slot Configuration matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (bucketCapacityOperatingHoursNamesToIdsMap.containsKey(storeSetupImport.Front_Time_Slot_Configuration__c)) {
                st.Front_Time_Slot_Configuration__c = bucketCapacityOperatingHoursNamesToIdsMap.get(storeSetupImport.Front_Time_Slot_Configuration__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The Bucket Capacity Operating Hours for the selected Front Time Slot Configuration on this Store Setup Import could not be found.');
            }

            //Check if a Bucket Capacity Operating Hours for the Back Time Slot Configuration matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (bucketCapacityOperatingHoursNamesToIdsMap.containsKey(storeSetupImport.Back_Time_Slot_Configuration__c)) {
                st.Back_Time_Slot_Configuration__c = bucketCapacityOperatingHoursNamesToIdsMap.get(storeSetupImport.Back_Time_Slot_Configuration__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The Bucket Capacity Operating Hours for the selected Back Time Slot Configuration on this Store Setup Import could not be found.');
            }

            //Check if a Store Hours Operating Hours matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (storeHoursOperatingHoursNamesToIdsMap.containsKey(storeSetupImport.Operating_Hours__c)) {
                st.OperatingHoursId = storeHoursOperatingHoursNamesToIdsMap.get(storeSetupImport.Operating_Hours__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The selected Operating Hours on this Store Setup Import could not be found.');
            }

            //Check if a Work Type for the Front Appointment Work Type matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (workTypeNamesToIdsMap.containsKey(storeSetupImport.Front_Appointment_Work_Type__c)) {
                st.Front_Appointment_Work_Type__c = workTypeNamesToIdsMap.get(storeSetupImport.Front_Appointment_Work_Type__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The Work Type for the selected Front Appointment Work Type on this Store Setup Import could not be found.');
            }

            //Check if a Work Type for the Back Appointment Work Type matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            if (workTypeNamesToIdsMap.containsKey(storeSetupImport.Back_Appointment_Work_Type__c)) {
                st.Back_Appointment_Work_Type__c = workTypeNamesToIdsMap.get(storeSetupImport.Back_Appointment_Work_Type__c);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The Work Type for the selected Back Appointment Work Type on this Store Setup Import could not be found.');
            }

            //Check if a POS Terminal User matches what was selected on the Store Setup Import and set it on the new Service Territory, if not then set an error on the Store Setup Import
            String posTerminalUser = String.isNotBlank(storeSetupImport.POS_Terminal_User__c) ? storeSetupImport.POS_Terminal_User__c : storeSetupImport.Store_ID__c;
            if (posTerminalUserNamesToIdsMap.containsKey(posTerminalUser)) {
                st.Appt_Record_Owner__c = posTerminalUserNamesToIdsMap.get(posTerminalUser);
            } else {
                Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'The POS Terminal User for this Store Setup Import could not be found. Please confirm there is an existing User with the "POS Store Terminal" Profile and the same Name as the given Store ID or POS Terminal User (if not blank).');
            }

            return st;
        }

        private List<ServiceTerritory> getServiceTerritoriesToInsert(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build List of Service Territories that need to be inserted
            List<ServiceTerritory> serviceTerritoriesToInsert = new List<ServiceTerritory>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
                if (Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport)) {
                    //If error previously occurred on the Store Setup Import, then skip the record (it will need to be reprocessed)
                    continue;
                }

                if (String.isBlank(storeSetupImport.Front_Room_Service_Resource__c)) {
                    //If the Store Setup Import has not been linked to a Front Room Service Resource record, then set an error and skip the record (it will need to be reprocessed)
                    Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'Front Room Service Resource was not found for this Store Setup Import. Please check the Logs for additional details.');
                    continue;
                }
                if (String.isBlank(storeSetupImport.Back_Room_Service_Resource__c)) {
                    //If the Store Setup Import has not been linked to a Back Room Service Resource record, then set an error and skip the record (it will need to be reprocessed)
                    Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'Back Room Service Resource was not found for this Store Setup Import. Please check the Logs for additional details.');
                    continue;
                }

                if (!existingServiceTerritoryNamesToRecordsMap.containsKey(storeSetupImport.Store_ID__c)) {
                    //If Service Territory does not already exist for given Store ID, then setup the Service Territory
                    ServiceTerritory st = setupServiceTerritory(storeSetupImport);
                    if (!Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport)) {
                        serviceTerritoriesToInsert.add(st);
                    }
                }
            }
            return serviceTerritoriesToInsert;
        }
    }

    //Wrapper class used to assist with processing the given Store Setup Import's related Service Territory Members
    public class ServiceTerritoryMemberConfiguration {

        //Map<ServiceTerritoryId, Set<ServiceResourceId>>
        private Map<String, Set<String>> existingServiceTerritoryMembersMap;

        public ServiceTerritoryMemberConfiguration(ServiceResourceConfiguration serviceResourceConfig, ServiceTerritoryConfiguration serviceTerritoryConfig) {
            setupExistingServiceTerritoryMembersMap(serviceResourceConfig, serviceTerritoryConfig);
        }

        private void setupExistingServiceTerritoryMembersMap(ServiceResourceConfiguration serviceResourceConfig, ServiceTerritoryConfiguration serviceTerritoryConfig) {
            //Build Map of existing Service Territory Members that will be used to ensure duplicate records are not attempted to be created
            existingServiceTerritoryMembersMap = new Map<String, Set<String>>();
            for (ServiceTerritoryMember stm : [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId IN :serviceResourceConfig.serviceResourceIds AND ServiceTerritoryId IN :serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.keySet()]) {
                if (!existingServiceTerritoryMembersMap.containsKey(stm.ServiceTerritoryId)) {
                    existingServiceTerritoryMembersMap.put(stm.ServiceTerritoryId, new Set<String>());
                }
                existingServiceTerritoryMembersMap.get(stm.ServiceTerritoryId).add(stm.ServiceResourceId);
            }
        }

        private ServiceTerritoryMember setupServiceTerritoryMember(String serviceResourceId, String serviceTerritoryId) {
            //Create new Service Territory Member record with the necessary data
            ServiceTerritoryMember stm = new ServiceTerritoryMember();
            stm.ServiceResourceId = serviceResourceId;
            stm.ServiceTerritoryId = serviceTerritoryId;
            stm.EffectiveStartDate = Datetime.now();

            return stm;
        }

        private List<ServiceTerritoryMember> getServiceTerritoryMembersToInsert(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build List of Service Territory Members that need to be inserted
            List<ServiceTerritoryMember> serviceTerritoryMembersToInsert = new List<ServiceTerritoryMember>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
                if (Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport)) {
                    //If error previously occurred on the Store Setup Import, then skip the record (it will need to be reprocessed)
                    continue;
                }

                if (String.isBlank(storeSetupImport.Service_Territory__c)) {
                    //If the Store Setup Import has not been linked to a Service Territory record, then set an error and skip the record (it will need to be reprocessed)
                    Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'Service Territory was not found for this Store Setup Import. Please check the Logs for additional details.');
                    continue;
                }

                Boolean frontRoomServiceTerritoryMemberExists = existingServiceTerritoryMembersMap.containsKey(storeSetupImport.Service_Territory__c) && existingServiceTerritoryMembersMap.get(storeSetupImport.Service_Territory__c).contains(storeSetupImport.Front_Room_Service_Resource__c);
                if (!frontRoomServiceTerritoryMemberExists && String.isNotBlank(storeSetupImport.Front_Room_Service_Resource__c) && String.isNotBlank(storeSetupImport.Service_Territory__c)) {
                    //If Service Territory Member does not already exist for Front Room Service Resource, then setup their Service Territory Member
                    serviceTerritoryMembersToInsert.add(setupServiceTerritoryMember(storeSetupImport.Front_Room_Service_Resource__c, storeSetupImport.Service_Territory__c));
                }

                Boolean backRoomServiceTerritoryMemberExists = existingServiceTerritoryMembersMap.containsKey(storeSetupImport.Service_Territory__c) && existingServiceTerritoryMembersMap.get(storeSetupImport.Service_Territory__c).contains(storeSetupImport.Back_Room_Service_Resource__c);
                if (!backRoomServiceTerritoryMemberExists && String.isNotBlank(storeSetupImport.Back_Room_Service_Resource__c) && String.isNotBlank(storeSetupImport.Service_Territory__c)) {
                    //If Service Territory Member does not already exist for Back Room Service Resource, then setup their Service Territory Member
                    serviceTerritoryMembersToInsert.add(setupServiceTerritoryMember(storeSetupImport.Back_Room_Service_Resource__c, storeSetupImport.Service_Territory__c));
                }
            }
            return serviceTerritoryMembersToInsert;
        }
    }

    //Wrapper class used to assist with processing the given Store Setup Import's related Appt Time Slot Capacities
    public class ApptTimeSlotCapacityConfiguration {

        //Map<ServiceTerritoryId, Set<TimeSlotUniqueKey(DayOfWeek|StartTime|EndTime)>>
        private Map<String, Set<String>> existingApptTimeSlotCapacitiesMap;

        //Map<DefaultGroupName, Map<TimeSlotUniqueKey(DayOfWeek|StartTime|EndTime), ApptTimeSlotCapacityDefault>>
        private Map<String, Map<String, Appt_Time_Slot_Capacity_Default__mdt>> apptTimeSlotCapacityDefaultsMap;

        public ApptTimeSlotCapacityConfiguration(ServiceTerritoryConfiguration serviceTerritoryConfig, StoreSetupImportConfiguration storeSetupImportConfig) {
            setupExistingApptTimeSlotCapacitiesMap(serviceTerritoryConfig);
            setupApptTimeSlotCapacityDefaultsMap(storeSetupImportConfig);
        }

        private void setupExistingApptTimeSlotCapacitiesMap(ServiceTerritoryConfiguration serviceTerritoryConfig) {
            //Build Map of existing Appt Time Slot Capacities that will be used to ensure duplicate records are not attempted to be created
            existingApptTimeSlotCapacitiesMap = new Map<String, Set<String>>();
            for (Appt_Time_Slot_Capacity__c atsc : [SELECT Id, Day_of_Week__c, Start_Time__c, End_Time__c, Service_Territory__c FROM Appt_Time_Slot_Capacity__c WHERE Service_Territory__c IN :serviceTerritoryConfig.serviceTerritoryIdsToStoreImportSetupIdsMap.keySet()]) {
                if (!existingApptTimeSlotCapacitiesMap.containsKey(atsc.Service_Territory__c)) {
                    existingApptTimeSlotCapacitiesMap.put(atsc.Service_Territory__c, new Set<String>());
                }
                existingApptTimeSlotCapacitiesMap.get(atsc.Service_Territory__c).add(Appt_StoreSetupUtil.getTimeSlotUniqueKey(atsc.Day_of_Week__c, atsc.Start_Time__c, atsc.End_Time__c));
            }
        }

        private void setupApptTimeSlotCapacityDefaultsMap(StoreSetupImportConfiguration storeSetupImportConfig) {
            //Build Map of Appt Time Slot Capacity Defaults that are setup in Custom Metadata that will be used to set Front/Back Room Capacities when creating Appt Time Slot Capacity records
            apptTimeSlotCapacityDefaultsMap = new Map<String, Map<String, Appt_Time_Slot_Capacity_Default__mdt>>();
            for (Appt_Time_Slot_Capacity_Default__mdt atscDefault : [SELECT BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, Default_Group_Name__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity_Default__mdt WHERE Default_Group_Name__c IN :storeSetupImportConfig.apptTimeSlotCapacityDefaultGroupNames]) {
                if (!apptTimeSlotCapacityDefaultsMap.containsKey(atscDefault.Default_Group_Name__c)) {
                    apptTimeSlotCapacityDefaultsMap.put(atscDefault.Default_Group_Name__c, new Map<String, Appt_Time_Slot_Capacity_Default__mdt>());
                }
                Time startTime = Time.newInstance(Integer.valueOf(atscDefault.Start_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.Start_Time__c.substring(2, 4)), 0, 0);
                Time endTime = Time.newInstance(Integer.valueOf(atscDefault.End_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.End_Time__c.substring(2, 4)), 0, 0);
                apptTimeSlotCapacityDefaultsMap.get(atscDefault.Default_Group_Name__c).put(Appt_StoreSetupUtil.getTimeSlotUniqueKey(atscDefault.Day_of_Week__c, startTime, endTime), atscDefault);
            }
        }

        private Appt_Time_Slot_Capacity__c setupApptTimeSlotCapacity(Store_Setup_Import__c storeSetupImport, String dayOfWeek, Time startTime, Time endTime) {
            //Create new Appt Time Slot Capacity record with the necessary data
            Appt_Time_Slot_Capacity__c atsc = new Appt_Time_Slot_Capacity__c();
            atsc.Service_Territory__c = storeSetupImport.Service_Territory__c;
            atsc.Day_of_Week__c = dayOfWeek;
            atsc.Start_Time__c = startTime;
            atsc.End_Time__c = endTime;
            atsc.BSF_Capacity__c = 0;
            atsc.BSR_Capacity__c = 0;
            atsc.BWF_Capacity__c = 0;
            atsc.BWR_Capacity__c = 0;
            atsc.FSF_Capacity__c = 0;
            atsc.FSR_Capacity__c = 0;
            atsc.FWF_Capacity__c = 0;
            atsc.FWR_Capacity__c = 0;

            //Set any Capacity defaults that are setup in the Appt Time Slot Capacity Default Custom Metadata Type
            String timeSlotUniqueKey = Appt_StoreSetupUtil.getTimeSlotUniqueKey(dayOfWeek, startTime, endTime);
            if (apptTimeSlotCapacityDefaultsMap.containsKey(storeSetupImport.Front_Back_Room_Default_Capacity_Group__c) && apptTimeSlotCapacityDefaultsMap.get(storeSetupImport.Front_Back_Room_Default_Capacity_Group__c).containsKey(timeSlotUniqueKey)) {
                Appt_Time_Slot_Capacity_Default__mdt atscDefault = apptTimeSlotCapacityDefaultsMap.get(storeSetupImport.Front_Back_Room_Default_Capacity_Group__c).get(timeSlotUniqueKey);
                atsc.BSF_Capacity__c = atscDefault.BSF_Capacity__c;
                atsc.BSR_Capacity__c = atscDefault.BSR_Capacity__c;
                atsc.BWF_Capacity__c = atscDefault.BWF_Capacity__c;
                atsc.BWR_Capacity__c = atscDefault.BWR_Capacity__c;
                atsc.FSF_Capacity__c = atscDefault.FSF_Capacity__c;
                atsc.FSR_Capacity__c = atscDefault.FSR_Capacity__c;
                atsc.FWF_Capacity__c = atscDefault.FWF_Capacity__c;
                atsc.FWR_Capacity__c = atscDefault.FWR_Capacity__c;
            }

            return atsc;
        }

        private List<Appt_Time_Slot_Capacity__c> getApptTimeSlotCapacitiesToInsert(StoreSetupImportConfiguration storeSetupImportConfig, ServiceTerritoryConfiguration serviceTerritoryConfig) {
            //Build List of Appt Time Slot Capacities that need to be inserted
            List<Appt_Time_Slot_Capacity__c> apptTimeSlotCapacitiesToInsert = new List<Appt_Time_Slot_Capacity__c>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportConfig.storeSetupImportIdsToRecordsMap.values()) {
                if (Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport)) {
                    //If error previously occurred on the Store Setup Import, then skip the record (it will need to be reprocessed)
                    continue;
                }

                //Loop through Time Slots for each Day of the Week on the Operating Hours and Bucket Capacity Operating Hours for the related Service Territory to determine what Appt Time Slot Capacities need to be created
                String storeHoursOperatingHoursId = serviceTerritoryConfig.storeHoursOperatingHoursNamesToIdsMap.containsKey(storeSetupImport.Operating_Hours__c) ? serviceTerritoryConfig.storeHoursOperatingHoursNamesToIdsMap.get(storeSetupImport.Operating_Hours__c) : null;
                String bucketCapacityOperatingHoursId = serviceTerritoryConfig.bucketCapacityOperatingHoursNamesToIdsMap.containsKey(storeSetupImport.Front_Time_Slot_Configuration__c) ? serviceTerritoryConfig.bucketCapacityOperatingHoursNamesToIdsMap.get(storeSetupImport.Front_Time_Slot_Configuration__c) : null;
                if (String.isNotBlank(storeHoursOperatingHoursId) && serviceTerritoryConfig.storeHoursOperatingHoursTimeSlotsMap.containsKey(storeHoursOperatingHoursId) && String.isNotBlank(bucketCapacityOperatingHoursId) && serviceTerritoryConfig.bucketCapacityOperatingHoursTimeSlotsMap.containsKey(bucketCapacityOperatingHoursId)) {
                    for (String dayOfWeek : serviceTerritoryConfig.storeHoursOperatingHoursTimeSlotsMap.get(storeHoursOperatingHoursId).keySet()) {
                        for (TimeSlot storeHoursTimeSlot : serviceTerritoryConfig.storeHoursOperatingHoursTimeSlotsMap.get(storeHoursOperatingHoursId).get(dayOfWeek)) {
                            if (serviceTerritoryConfig.bucketCapacityOperatingHoursTimeSlotsMap.get(bucketCapacityOperatingHoursId).containsKey(dayOfWeek)) {
                                for (TimeSlot bucketCapacityTimeSlot : serviceTerritoryConfig.bucketCapacityOperatingHoursTimeSlotsMap.get(bucketCapacityOperatingHoursId).get(dayOfWeek)) {
                                    if (bucketCapacityTimeSlot.StartTime >= storeHoursTimeSlot.StartTime && bucketCapacityTimeSlot.EndTime <= storeHoursTimeSlot.EndTime) {
                                        String timeSlotUniqueKey = Appt_StoreSetupUtil.getTimeSlotUniqueKey(dayOfWeek, bucketCapacityTimeSlot.StartTime, bucketCapacityTimeSlot.EndTime);
                                        if (String.isNotBlank(storeSetupImport.Service_Territory__c) && (!existingApptTimeSlotCapacitiesMap.containsKey(storeSetupImport.Service_Territory__c) || (existingApptTimeSlotCapacitiesMap.containsKey(storeSetupImport.Service_Territory__c) && !existingApptTimeSlotCapacitiesMap.get(storeSetupImport.Service_Territory__c).contains(timeSlotUniqueKey)))) {
                                            //If Appt Time Slot Capacity does not already exist for this Time Slot, then setup the Appt Time Slot Capacity
                                            apptTimeSlotCapacitiesToInsert.add(setupApptTimeSlotCapacity(storeSetupImport, dayOfWeek, bucketCapacityTimeSlot.StartTime, bucketCapacityTimeSlot.EndTime));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return apptTimeSlotCapacitiesToInsert;
        }
    }
}