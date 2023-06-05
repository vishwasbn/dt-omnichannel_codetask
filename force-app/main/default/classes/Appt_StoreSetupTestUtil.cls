/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 6/3/22
 * @description Utility class used to assist with unit tests related to the Automated Store Setup Batch Processes
 */

@IsTest
public without sharing class Appt_StoreSetupTestUtil {

    public static final String STORE_PREFIX = 'ABC';

    public static FSL__Scheduling_Policy__c createSchedulingPolicy(String name) {
        //Create Scheduling Policy
        FSL__Scheduling_Policy__c sp = new FSL__Scheduling_Policy__c();
        sp.Name = name;
        insert sp;

        return sp;
    }

    public static WorkType createWorkType(String name, Integer estimatedDuration, String durationType) {
        //Create Work Type
        WorkType wt = new WorkType();
        wt.Name = name;
        wt.EstimatedDuration = estimatedDuration;
        wt.DurationType = durationType;
        insert wt;

        return wt;
    }

    public static List<User> createPOSTerminalUsers(Integer numUsersToCreate, String storePrefix, String aliasPrefix) {
        Id posStoreTerminalProfileId = [SELECT Id FROM Profile WHERE Name = 'POS Store Terminal'].Id;
        Id posStoreTerminalRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'POS_Store_Terminal'].Id;
        Id fieldServiceAgentPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FSL_Agent_Permissions'].Id;

        //Create POS Terminal Users
        List<User> posTerminalUsersToInsert = new List<User>();
        for (Integer i = 1; i <= numUsersToCreate; i++) {
            User u = new User();
            if (i < 10) {
                u.LastName = storePrefix + '0' + i + '_POS';
                u.Alias = aliasPrefix + '0' + i + 'po';
                u.UserName = aliasPrefix.deleteWhitespace() + '0' + i + '_pos@invalid.example.com.test';
            } else {
                u.LastName = storePrefix + i + '_POS';
                u.Alias = aliasPrefix + i + 'po';
                u.UserName = aliasPrefix.deleteWhitespace() + i + '_pos@invalid.example.com.test';
            }
            u.ProfileId = posStoreTerminalProfileId;
            u.UserRoleId = posStoreTerminalRoleId;
            u.IsActive = true;
            u.Email = 'test@invalid.example.com.test';
            u.LocaleSidKey = 'en_US';
            u.EmailEncodingKey = 'ISO-8859-1';
            u.LanguageLocaleKey = 'en_US';
            u.TimeZoneSidKey = 'America/Phoenix';
            posTerminalUsersToInsert.add(u);
        }
        insert posTerminalUsersToInsert;

        //Create POS Terminal User Permission Set Assignments
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        for (User u : posTerminalUsersToInsert) {
            permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = fieldServiceAgentPermissionSetId));
        }
        insert permissionSetAssignmentsToInsert;

        return posTerminalUsersToInsert;
    }

    public static List<User> createFrontAndBackUsers(Integer numSetsOfUsersToCreate, String storePrefix, String aliasPrefix) {
        Id standardUserCloneProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User Clone Profile'].Id;
        Id fieldServiceResourceLicensePermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FSL_Resource_License'].Id;
        Id fieldServiceResourcePermissionsPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'FSL_Resource_Permissions'].Id;

        //Create Front and Back Users
        List<User> usersToInsert = new List<User>();
        for (Integer i = 1; i <= numSetsOfUsersToCreate; i++) {
            //Create Front User
            User frontUser = new User();
            if (i < 10) {
                frontUser.LastName = storePrefix + '0' + i + '_FrontRm';
                frontUser.Alias = aliasPrefix + '0' + i + 'fr';
                frontUser.UserName = aliasPrefix + '0' + i + '_frontrm@invalid.example.com.test';
            } else {
                frontUser.LastName = storePrefix + i + '_FrontRm';
                frontUser.Alias = aliasPrefix + i + 'fr';
                frontUser.UserName = aliasPrefix + i + '_frontrm@invalid.example.com.test';
            }
            frontUser.ProfileId = standardUserCloneProfileId;
            frontUser.IsActive = true;
            frontUser.Email = 'test@invalid.example.com.test';
            frontUser.LocaleSidKey = 'en_US';
            frontUser.EmailEncodingKey = 'ISO-8859-1';
            frontUser.LanguageLocaleKey = 'en_US';
            frontUser.TimeZoneSidKey = 'America/Phoenix';
            usersToInsert.add(frontUser);

            //Create Back User
            User backUser = new User();
            if (i < 10) {
                backUser.LastName = storePrefix + '0' + i + '_BackRm';
                backUser.Alias = aliasPrefix + '0' + i + 'br';
                backUser.UserName = aliasPrefix + '0' + i + '_backrm@invalid.example.com.test';
            } else {
                backUser.LastName = storePrefix + i + '_BackRm';
                backUser.Alias = aliasPrefix + i + 'br';
                backUser.UserName = aliasPrefix + i + '_backrm@invalid.example.com.test';
            }
            backUser.ProfileId = standardUserCloneProfileId;
            backUser.IsActive = true;
            backUser.Email = 'test@invalid.example.com.test';
            backUser.LocaleSidKey = 'en_US';
            backUser.EmailEncodingKey = 'ISO-8859-1';
            backUser.LanguageLocaleKey = 'en_US';
            backUser.TimeZoneSidKey = 'America/Phoenix';
            usersToInsert.add(backUser);
        }
        insert usersToInsert;

        //Create Front and Back Users Permission Set Assignments
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        for (User u : usersToInsert) {
            permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = fieldServiceResourceLicensePermissionSetId));
            permissionSetAssignmentsToInsert.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = fieldServiceResourcePermissionsPermissionSetId));
        }
        insert permissionSetAssignmentsToInsert;

        return usersToInsert;
    }

    public static List<Account> createSiteAccounts(Integer numAccountsToCreate, String storePrefix) {
        Id siteAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site').getRecordTypeId();

        //Create Site Accounts
        List<Account> siteAccountsToInsert = new List<Account>();
        for (Integer i = 1; i <= numAccountsToCreate; i++) {
            String accountName;
            String accountStoreID;
            if (i < 10) {
                accountName = 'Test Account - ' + storePrefix + '0' + i;
                accountStoreID = storePrefix + '0' + i;
            } else {
                accountName = 'Test Account - ' + storePrefix + i;
                accountStoreID = storePrefix + i;
            }

            Account a = new Account();
            a.Name = accountName;
            a.RecordTypeId = siteAccountRecordTypeId;
            a.Store_ID__c = accountStoreID;
            a.SAP_STORE_ID__c = String.valueOf(2000 + i);
            a.Store_Status__c = 'Open';
            a.ShippingCountry = 'United States';
            a.Country__c = 'United States';
            a.Store_DBA_Name__c = 'TEST';
            a.Store_Public_Phone__c = '123-456-7890';
            a.Email__c = 'test@invalid.example.com.test';
            siteAccountsToInsert.add(a);
        }
        insert siteAccountsToInsert;

        return siteAccountsToInsert;
    }

    public static OperatingHours createOperatingHours(String name, String timeZone, String type) {
        //Create Operating Hours
        OperatingHours oh = new OperatingHours();
        oh.Name = name;
        oh.TimeZone = timeZone;
        oh.Type__c = type;
        insert oh;

        //Create Time Slots based on passed in Type
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        Time startTime = Time.newInstance(8, 0, 0, 0);
        Time mondayToFridayEndTime = Time.newInstance(18, 0, 0, 0);
        Time saturdayEndTime = Time.newInstance(17, 0, 0, 0);
        if (type.equalsIgnoreCase(Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS)) {
            //Create Full Day Time Slots for Monday-Friday 8AM-6PM, Saturday 8AM-5PM
            timeSlots.add(new TimeSlot(DayOfWeek = 'Monday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = mondayToFridayEndTime, OperatingHoursId = oh.Id));
            timeSlots.add(new TimeSlot(DayOfWeek = 'Tuesday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = mondayToFridayEndTime, OperatingHoursId = oh.Id));
            timeSlots.add(new TimeSlot(DayOfWeek = 'Wednesday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = mondayToFridayEndTime, OperatingHoursId = oh.Id));
            timeSlots.add(new TimeSlot(DayOfWeek = 'Thursday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = mondayToFridayEndTime, OperatingHoursId = oh.Id));
            timeSlots.add(new TimeSlot(DayOfWeek = 'Friday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = mondayToFridayEndTime, OperatingHoursId = oh.Id));
            timeSlots.add(new TimeSlot(DayOfWeek = 'Saturday', StartTime = Time.newInstance(8, 0, 0, 0), EndTime = saturdayEndTime, OperatingHoursId = oh.Id));

        } else if (type.equalsIgnoreCase(Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY)) {
            //Create 15 Minutes Time Slots with 4 Bucket Capacity for Monday-Friday 8AM-6PM, Saturday 8AM-5PM
            Time currentTime = startTime;
            Integer minutesToAdd = 15;
            Integer bucketCapacity = 4;
            Boolean createTimeSlots = true;
            while (createTimeSlots) {
                Time endTime = currentTime.addMinutes(minutesToAdd);
                timeSlots.add(new TimeSlot(DayOfWeek = 'Monday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                timeSlots.add(new TimeSlot(DayOfWeek = 'Tuesday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                timeSlots.add(new TimeSlot(DayOfWeek = 'Wednesday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                timeSlots.add(new TimeSlot(DayOfWeek = 'Thursday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                timeSlots.add(new TimeSlot(DayOfWeek = 'Friday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                if (currentTime < saturdayEndTime) {
                    timeSlots.add(new TimeSlot(DayOfWeek = 'Saturday', StartTime = currentTime, EndTime = endTime, OperatingHoursId = oh.Id, FSF_Capacity__c = bucketCapacity, FSR_Capacity__c = bucketCapacity, FWF_Capacity__c = bucketCapacity, FWR_Capacity__c = bucketCapacity, BSF_Capacity__c = bucketCapacity, BSR_Capacity__c = bucketCapacity, BWF_Capacity__c = bucketCapacity, BWR_Capacity__c = bucketCapacity));
                }
                currentTime = currentTime.addMinutes(minutesToAdd);
                createTimeSlots = currentTime < mondayToFridayEndTime;
            }

        }
        insert timeSlots;

        return oh;
    }

    public static List<Store_Setup_Import__c> createStoreSetupImports(Integer numStoreSetupImportsToCreate, String storePrefix, OperatingHours storeHoursOH, OperatingHours bucketCapacityOH, FSL__Scheduling_Policy__c sp, WorkType wt) {
        //Create Store Setup Imports
        List<Store_Setup_Import__c> storeSetupImports = new List<Store_Setup_Import__c>();
        for (Integer i = 1; i <= numStoreSetupImportsToCreate; i++) {
            String storeName;
            if (i < 10) {
                storeName = storePrefix + '0' + i;
            } else {
                storeName = storePrefix + i;
            }

            Store_Setup_Import__c ssi = new Store_Setup_Import__c();
            ssi.Store_ID__c = storeName;
            ssi.POS_Terminal_User__c = storeName + '_POS';
            ssi.Store_Is_Active__c = true;
            ssi.Operating_Hours__c = storeHoursOH.Name;
            ssi.Front_Time_Slot_Configuration__c = bucketCapacityOH.Name;
            ssi.Back_Time_Slot_Configuration__c = bucketCapacityOH.Name;
            ssi.Scheduling_Policy__c = sp.Name;
            ssi.Front_Appointment_Work_Type__c = wt.Name;
            ssi.Back_Appointment_Work_Type__c = wt.Name;
            ssi.Front_Back_Room_Default_Capacity_Group__c = '(M-F 8-6, Sat 8-5) Store Hours - 15 Minute Time Slots';
            ssi.Front_Back_Room_User_Email__c = 'sfdc_deadletter@discounttire.com';
            ssi.Front_Back_Room_Resource_Type__c = 'T';
            ssi.Front_Back_Room_Profile__c = 'Standard User Clone Profile';
            ssi.Front_Back_Room_User_Permission_Set__c = 'N/A';
            storeSetupImports.add(ssi);
        }
        insert storeSetupImports;

        return storeSetupImports;
    }
}