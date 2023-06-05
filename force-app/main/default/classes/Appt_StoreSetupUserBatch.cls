/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/26/22
 * @description Batch Class used to create Front/Back Room Users and Permission Set Assignments during the Automated Store Setup Process
 */

public without sharing class Appt_StoreSetupUserBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents {
    private final String LOG_CLASS_NAME = 'Appt_StoreSetupUserBatch';

    //Maps used to track Front/Back Users to their related Store Setup Import so they can be passed into Appt_StoreSetupServiceTerritoryBatch and set on the Front/Back Room User Lookup fields on the related Store Setup Import record
    private Map<String, String> storeSetupImportIdsToFrontUserIdsMap;
    private Map<String, String> storeSetupImportIdsToBackUserIdsMap;

    //Map used to track Errors to their related Store Setup Import (if any occur) so they can be passed into Appt_StoreSetupServiceTerritoryBatch and set on the User Creation Message field on the related Store Setup Import record
    private Map<String, String> storeSetupImportIdsToUserErrorsMap;

    private List<String> selectedStoreSetupImportIds;
    private String currentUserEmail;

    public Appt_StoreSetupUserBatch(List<String> selectedStoreImportIds, String currentUserEmail) {
        this.selectedStoreSetupImportIds = selectedStoreImportIds != null && !selectedStoreImportIds.isEmpty() ? selectedStoreImportIds : new List<String>();
        this.currentUserEmail = currentUserEmail;
        storeSetupImportIdsToFrontUserIdsMap = new Map<String, String>();
        storeSetupImportIdsToBackUserIdsMap = new Map<String, String>();
        storeSetupImportIdsToUserErrorsMap = new Map<String, String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!selectedStoreSetupImportIds.isEmpty()) {
            //If Store Setup Imports were selected, then query for those records only
            return Database.getQueryLocator([SELECT Id, Name, Front_Back_Room_User_Email__c, Front_Back_Room_User_Permission_Set__c, Front_Back_Room_Profile__c, Operating_Hours__c, Store_ID__c FROM Store_Setup_Import__c WHERE Id IN :selectedStoreSetupImportIds]);
        } else {
            //If no Store Setup Imports were selected, then query for all records with a User Creation Status of "Ready"
            return Database.getQueryLocator([SELECT Id, Name, Front_Back_Room_User_Email__c, Front_Back_Room_User_Permission_Set__c, Front_Back_Room_Profile__c, Operating_Hours__c, Store_ID__c FROM Store_Setup_Import__c WHERE User_Creation_Status__c = :Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY]);
        }
    }

    public void execute(Database.BatchableContext bc, List<Store_Setup_Import__c> storeSetupImports) {
        //Create/Process Users and Permission Set Assignments
        UserConfiguration userConfig = new UserConfiguration(storeSetupImports);
        List<User> usersToInsert = userConfig.getUsersToInsert(storeSetupImportIdsToUserErrorsMap);
        processUsersAndPermissionSetAssignments(usersToInsert, userConfig);
    }

    public void finish(Database.BatchableContext bc) {
        //Upon completion of this Batch, start the Appt_StoreSetupServiceTerritoryBatch process to create the necessary Service Territories and related records
        String storeSetupServiceTerritoryBatchSizeString = Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_STORE_SETUP_SERVICE_TERRITORY_BATCH_SIZE);
        Integer storeSetupServiceTerritoryBatchSize = String.isNotBlank(storeSetupServiceTerritoryBatchSizeString) ? Integer.valueOf(storeSetupServiceTerritoryBatchSizeString) : 20;
        Appt_StoreSetupServiceTerritoryBatch setupServiceTerritoryBatch = new Appt_StoreSetupServiceTerritoryBatch(selectedStoreSetupImportIds, storeSetupImportIdsToFrontUserIdsMap, storeSetupImportIdsToBackUserIdsMap, storeSetupImportIdsToUserErrorsMap, currentUserEmail);
        Database.executeBatch(setupServiceTerritoryBatch, storeSetupServiceTerritoryBatchSize);
    }

    @AuraEnabled
    public static void startStoreSetupUserBatch(List<String> selectedStoreSetupImportIds, String currentUserEmail) {
        //Method used within the apptAutomatedStoreSetup LWC to kickoff the Automated Store Setup process
        String storeSetupUserBatchSizeString = Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_STORE_SETUP_USER_BATCH_SIZE);
        Integer storeSetupUserBatchSize = String.isNotBlank(storeSetupUserBatchSizeString) ? Integer.valueOf(storeSetupUserBatchSizeString) : 100;
        Database.executeBatch(new Appt_StoreSetupUserBatch(selectedStoreSetupImportIds, currentUserEmail), storeSetupUserBatchSize);
    }

    private void processUsersAndPermissionSetAssignments(List<User> usersToInsert, UserConfiguration userConfig) {
        //Initialize Logger instance
        Logger logInstance = Logger.getInstance(true);

        if (!usersToInsert.isEmpty()) {
            //If there are Users to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(usersToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'User', saveResults);
        }

        //Create a List of Users to process that includes the newly inserted Users as well as any existing Users related to the given Store Setup Imports
        List<User> usersToProcess = new List<User>(usersToInsert);
        usersToProcess.addAll(userConfig.existingFrontUserNamesToRecordsMap.values());
        usersToProcess.addAll(userConfig.existingBackUserNamesToRecordsMap.values());

        //Track Front and Back Users in Maps that will be passed in to Appt_StoreSetupServiceTerritoryBatch and also build List of Permission Set Assignments that need to be inserted
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        for (User u : usersToProcess) {
            String name = u.LastName;
            if (u.Id != null) {
                if (String.isNotBlank(u.Name)) {
                    name = u.Name;
                }
                name = name.deleteWhitespace();
                List<String> splitLastName = name.split(Appt_StoreSetupUtil.FRONT_BACK_ROOM_USER_NAME_POSTFIX_SEPARATOR);
                if (!splitLastName.isEmpty() && splitLastName.size() == 2) {
                    String storeName = splitLastName[0];
                    String namePostfix = splitLastName[1];
                    if (userConfig.storeSetupImportNamesToRecordsMap.containsKey(storeName)) {
                        Store_Setup_Import__c storeSetupImport = userConfig.storeSetupImportNamesToRecordsMap.get(storeName);
                        if (namePostfix.equalsIgnoreCase(Appt_StoreSetupUtil.FRONT_ROOM_USER_NAME_POSTFIX)) {
                            storeSetupImportIdsToFrontUserIdsMap.put(storeSetupImport.Id, u.Id);
                        } else if (namePostfix.equalsIgnoreCase(Appt_StoreSetupUtil.BACK_ROOM_USER_NAME_POSTFIX)) {
                            storeSetupImportIdsToBackUserIdsMap.put(storeSetupImport.Id, u.Id);
                        }
                        Set<String> permissionSetLabels = Appt_StoreSetupUtil.getAutoAssignedFieldServiceResourcePermissionSetLabels();
                        if (String.isNotBlank(storeSetupImport.Front_Back_Room_User_Permission_Set__c)) {
                            //If Front & Back Room User Permission Set is not blank, then split value by the ";" character and remove the default "N/A" value before adding to the full list of Permission Set Labels
                            Set<String> splitPermissionSets = new Set<String>(storeSetupImport.Front_Back_Room_User_Permission_Set__c.split(';'));
                            splitPermissionSets.remove('N/A');
                            permissionSetLabels.addAll(splitPermissionSets);
                        }
                        for (String permissionSetLabel : permissionSetLabels) {
                            if (userConfig.existingFrontBackUserIdsToAssignedPermissionSetLabelsMap.containsKey(u.Id) && userConfig.existingFrontBackUserIdsToAssignedPermissionSetLabelsMap.get(u.Id).contains(permissionSetLabel)) {
                                //If existing User already has Permission Set assigned to them, then continue to next Permission Set
                                continue;
                            }

                            //Check if the given Permission Set from the Store Setup Import is valid and setup the Permission Set Assignment for the given User, if not then set an error on the Store Setup Import
                            if (userConfig.permissionSetLabelsToIdsMap.containsKey(permissionSetLabel)) {
                                permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = userConfig.permissionSetLabelsToIdsMap.get(permissionSetLabel)));
                            } else {
                                Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'Permission Set Label \'' + permissionSetLabel + '\' is not valid so it could not be assigned to User ' + name + ' (' + u.Id + ').');
                            }
                        }
                    } else {
                        logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'User ' + name + ' (' + u.Id + ') is associated with an unexpected Store Name (' + storeName + ') that could not be matched to an existing Store Setup Import record. Due to this error, Permission Set Assignments could not be validated for this User.');
                    }
                } else {
                    logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'User ' + name + ' (' + u.Id + ') has an unexpected Name that could not be split correctly using the \'' + Appt_StoreSetupUtil.FRONT_BACK_ROOM_USER_NAME_POSTFIX_SEPARATOR + '\' character. Due to this error, Permission Set Assignments could not be validated for this User.');
                }
            } else {
                logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, Logger.Level.ERROR, 'User ' + name + ' could not be created. Please check the Logs for additional details.');
            }
        }

        if (!permissionSetAssignmentsToInsert.isEmpty()) {
            //If there are Permission Set Assignments to insert, then insert them and track any errors
            List<Database.SaveResult> saveResults = Database.insert(permissionSetAssignmentsToInsert, false);
            logInstance.log(Appt_StoreSetupUtil.LOG_IDENTIFIER, LOG_CLASS_NAME, 'PermissionSetAssignment', saveResults);
        }

        //Insert Logs, if any were created
        logInstance.finalize();
    }

    //Wrapper class used to assist with processing the given Store Setup Import's related Users
    public class UserConfiguration {
        private Map<String, Store_Setup_Import__c> storeSetupImportNamesToRecordsMap;

        private Map<String, Id> permissionSetLabelsToIdsMap;
        private Map<String, Id> profileNamesToIdsMap;

        private Map<String, String> operatingHoursNamesToTimezonesMap;

        private Map<String, User> existingFrontUserNamesToRecordsMap;
        private Map<String, User> existingBackUserNamesToRecordsMap;

        private Set<String> existingFrontBackUserIds;

        private String defaultUsernameDomain;
        private String sandboxName;

        //Map<PermissionSetAssignmentAssigneeId, Set<PermissionSetLabel>>
        private Map<String, Set<String>> existingFrontBackUserIdsToAssignedPermissionSetLabelsMap;

        public UserConfiguration(List<Store_Setup_Import__c> storeSetupImports) {
            storeSetupImportNamesToRecordsMap = new Map<String, Store_Setup_Import__c>();
            defaultUsernameDomain = Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_AUTOMATED_FRONT_BACK_USERNAME_DOMAIN);
            sandboxName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();

            //Build Sets of Names/Labels that will be used to setup various Maps
            Set<String> permissionSetLabels = Appt_StoreSetupUtil.getAutoAssignedFieldServiceResourcePermissionSetLabels();
            Set<String> possibleFrontBackUserNames = new Set<String>();
            Set<String> profileNames = new Set<String>();
            Set<String> operatingHoursNames = new Set<String>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImports) {
                storeSetupImportNamesToRecordsMap.put(storeSetupImport.Store_ID__c.deleteWhitespace(), storeSetupImport);
                possibleFrontBackUserNames.add(Appt_StoreSetupUtil.getExpectedFrontUserNameForStoreName(storeSetupImport.Store_ID__c));
                possibleFrontBackUserNames.add(Appt_StoreSetupUtil.getExpectedFrontUserNameForStoreName(storeSetupImport.Store_ID__c.deleteWhitespace()));
                possibleFrontBackUserNames.add(Appt_StoreSetupUtil.getExpectedBackUserNameForStoreName(storeSetupImport.Store_ID__c));
                possibleFrontBackUserNames.add(Appt_StoreSetupUtil.getExpectedBackUserNameForStoreName(storeSetupImport.Store_ID__c.deleteWhitespace()));
                profileNames.add(storeSetupImport.Front_Back_Room_Profile__c);
                operatingHoursNames.add(storeSetupImport.Operating_Hours__c);
                if (String.isNotBlank(storeSetupImport.Front_Back_Room_User_Permission_Set__c)) {
                    permissionSetLabels.addAll(storeSetupImport.Front_Back_Room_User_Permission_Set__c.split(';'));
                }
            }

            setupPermissionSetLabelsToIdsMap(permissionSetLabels);
            setupProfileNamesToIdsMap(profileNames);
            setupOperatingHoursNamesToTimezonesMap(operatingHoursNames);
            setupExistingUserVariables(possibleFrontBackUserNames);
            setupExistingFrontBackUserIdsToAssignedPermissionSetLabelsMap();
        }

        private void setupPermissionSetLabelsToIdsMap(Set<String> permissionSetLabels) {
            //Build Map of Permission Sets
            permissionSetLabelsToIdsMap = new Map<String, Id>();
            for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE Label IN :permissionSetLabels]) {
                permissionSetLabelsToIdsMap.put(ps.Label, ps.Id);
            }
        }

        private void setupProfileNamesToIdsMap(Set<String> profileNames) {
            //Build Map of Profiles
            profileNamesToIdsMap = new Map<String, Id>();
            for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
                profileNamesToIdsMap.put(p.Name, p.Id);
            }
        }

        private void setupOperatingHoursNamesToTimezonesMap(Set<String> operatingHoursNames) {
            //Build Map of Operating Hours
            operatingHoursNamesToTimezonesMap = new Map<String, String>();
            for (OperatingHours oh : [SELECT Id, Name, TimeZone FROM OperatingHours WHERE Name IN :operatingHoursNames]) {
                operatingHoursNamesToTimezonesMap.put(oh.Name, oh.TimeZone);
            }
        }

        private void setupExistingUserVariables(Set<String> possibleFrontBackUserNames) {
            //Build Maps of existing Users that will be used to ensure duplicate records are not attempted to be created
            existingFrontUserNamesToRecordsMap = new Map<String, User>();
            existingBackUserNamesToRecordsMap = new Map<String, User>();
            existingFrontBackUserIds = new Set<String>();
            for (User u : [SELECT Id, LastName, Name FROM User WHERE Name IN :possibleFrontBackUserNames]) {
                if (u.Name.containsIgnoreCase(Appt_StoreSetupUtil.FRONT_ROOM_USER_NAME_POSTFIX)) {
                    existingFrontUserNamesToRecordsMap.put(u.Name, u);
                    existingFrontBackUserIds.add(u.Id);
                } else if (u.Name.containsIgnoreCase(Appt_StoreSetupUtil.BACK_ROOM_USER_NAME_POSTFIX)) {
                    existingBackUserNamesToRecordsMap.put(u.Name, u);
                    existingFrontBackUserIds.add(u.Id);
                }
            }
        }

        private void setupExistingFrontBackUserIdsToAssignedPermissionSetLabelsMap() {
            //Build Map of existing Permission Set Assignments that will be used to ensure duplicate records are not attempted to be created
            existingFrontBackUserIdsToAssignedPermissionSetLabelsMap = new Map<String, Set<String>>();
            for (PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId IN :existingFrontBackUserIds AND PermissionSetId IN :permissionSetLabelsToIdsMap.values()]) {
                if (!existingFrontBackUserIdsToAssignedPermissionSetLabelsMap.containsKey(psa.AssigneeId)) {
                    existingFrontBackUserIdsToAssignedPermissionSetLabelsMap.put(psa.AssigneeId, new Set<String>());
                }
                existingFrontBackUserIdsToAssignedPermissionSetLabelsMap.get(psa.AssigneeId).add(psa.PermissionSet.Label);
            }
        }

        private User setupUser(Store_Setup_Import__c storeSetupImport, String lastName, Id profileId, String timezone) {
            //Delete whitespace within passed in Last Name to prevent errors and ensure naming consistency in the created Front/Back Room Users
            lastName = lastName.deleteWhitespace();

            //Create new User record with the necessary data
            User u = new User();
            u.LastName = lastName;
            u.ProfileId = profileId;
            u.UserPermissionsSupportUser = true;
            u.LocaleSidKey = 'en_US';
            u.EmailEncodingKey = 'ISO-8859-1';
            u.LanguageLocaleKey = 'en_US';
            u.TimeZoneSidKey = timezone;

            //Set new User's Alias based on if they are a Front User or a Back User
            if (lastName.containsIgnoreCase(Appt_StoreSetupUtil.FRONT_ROOM_USER_NAME_POSTFIX)) {
                u.Alias = storeSetupImport.Store_ID__c + 'fr';
            } else if (lastName.containsIgnoreCase(Appt_StoreSetupUtil.BACK_ROOM_USER_NAME_POSTFIX)) {
                u.Alias = storeSetupImport.Store_ID__c + 'br';
            }

            //Set new User's Email
            u.Email = storeSetupImport.Front_Back_Room_User_Email__c;
            if (String.isNotBlank(sandboxName) && !u.Email.endsWithIgnoreCase(sandboxName)) {
                //If running in a Sandbox and the Email does not end with the Sandbox name, then append the Sandbox name to the Email
                u.Email += '.' + sandboxName;
            }

            if (String.isNotBlank(defaultUsernameDomain)) {
                //If default Username Domain is provided, then set Username (if no default is provided, then an error will be logged when attempting to insert the Users)
                u.Username = u.LastName + defaultUsernameDomain;
                if (String.isNotBlank(sandboxName) && !defaultUsernameDomain.endsWithIgnoreCase(sandboxName)) {
                    //If running in a Sandbox and the default Username Domain does not end with the Sandbox name, then append the Sandbox name to the Username
                    u.Username += '.' + sandboxName;
                }
            }

            return u;
        }

        private List<User> getUsersToInsert(Map<String, String> storeSetupImportIdsToUserErrorsMap) {
            //Build List of Users that need to be inserted
            List<User> usersToInsert = new List<User>();
            for (Store_Setup_Import__c storeSetupImport : storeSetupImportNamesToRecordsMap.values()) {
                //Get the Front/Back User's Names
                String frontUserName = Appt_StoreSetupUtil.getExpectedFrontUserNameForStoreName(storeSetupImport.Store_ID__c);
                String backUserName = Appt_StoreSetupUtil.getExpectedBackUserNameForStoreName(storeSetupImport.Store_ID__c);

                //Determine the correct Profile for the new Users
                Id profileId;
                if (profileNamesToIdsMap.containsKey(storeSetupImport.Front_Back_Room_Profile__c)) {
                    profileId = profileNamesToIdsMap.get(storeSetupImport.Front_Back_Room_Profile__c);
                }

                //Determine the correct Timezone for the new Users
                String timezone;
                if (operatingHoursNamesToTimezonesMap.containsKey(storeSetupImport.Operating_Hours__c)) {
                    timezone = operatingHoursNamesToTimezonesMap.get(storeSetupImport.Operating_Hours__c);
                }

                //Check if Front Room User needs to be created
                if (!existingFrontUserNamesToRecordsMap.containsKey(frontUserName) && !existingFrontUserNamesToRecordsMap.containsKey(frontUserName.deleteWhitespace())) {
                    if (profileId != null && String.isNotBlank(timezone)) {
                        //If User does not already exist for Front Room User, then setup their User
                        usersToInsert.add(setupUser(storeSetupImport, frontUserName, profileId, timezone));
                    } else if (profileId != null && String.isBlank(timezone)) {
                        //If User does not already exist for Front Room User but an Operating Hours Timezone was not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Operating Hours\' could not be found. Due to this error, the Front Room User could not be created.');
                    } else if (profileId == null && String.isNotBlank(timezone)) {
                        //If User does not already exist for Front Room User but a Profile was not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Front and Back Room User Profile\' could not be found. Due to this error, the Front Room User could not be created.');
                    } else {
                        //If User does not already exist for Front Room User but a Profile and Operating Hours Timezone were not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Front and Back Room User Profile\' and \'Operating Hours\' could not be found. Due to this error, the Front Room User could not be created.');
                    }
                }

                //Check if Back Room User needs to be created
                if (!existingBackUserNamesToRecordsMap.containsKey(backUserName) && !existingBackUserNamesToRecordsMap.containsKey(backUserName.deleteWhitespace())) {
                    if (profileId != null && String.isNotBlank(timezone)) {
                        //If User does not already exist for Back Room User, then setup their User
                        usersToInsert.add(setupUser(storeSetupImport, backUserName, profileId, timezone));
                    } else if (profileId != null && String.isBlank(timezone)) {
                        //If User does not already exist for Back Room User but an Operating Hours Timezone was not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Operating Hours\' could not be found. Due to this error, the Back Room User could not be created.');
                    } else if (profileId == null && String.isNotBlank(timezone)) {
                        //If User does not already exist for Back Room User but a Profile was not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Front and Back Room User Profile\' could not be found. Due to this error, the Back Room User could not be created.');
                    } else {
                        //If User does not already exist for Back Room User but a Profile and Operating Hours Timezone were not found, then set an error on the Store Setup Import
                        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImport.Id, 'The requested \'Front and Back Room User Profile\' and \'Operating Hours\' could not be found. Due to this error, the Back Room User could not be created.');
                    }
                }
            }
            return usersToInsert;
        }
    }
}