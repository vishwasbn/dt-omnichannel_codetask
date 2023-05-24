/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/26/22
 * @description Test class for the Appt_StoreSetupUserBatch class
 */

@IsTest
private class Appt_StoreSetupUserBatchTest {

    @IsTest
    static void testStoreSetupUserBatch() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Appt_StoreSetupTestUtil.createPOSTerminalUsers(1, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
        }

        Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        Set<Id> autoAssignedFieldServiceResourcePermissionSetIds = new Set<Id>();
        for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE Label IN :Appt_StoreSetupUtil.getAutoAssignedFieldServiceResourcePermissionSetLabels()]) {
            autoAssignedFieldServiceResourcePermissionSetIds.add(ps.Id);
        }

        Test.startTest();

        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Room_User__c, Front_Room_User__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.User_Creation_Status__c);

        //Validate Front Room User
        User frontUser = [SELECT Id, Alias, Email, EmailEncodingKey, LanguageLocaleKey, LastName, LocaleSidKey, Profile.Name, TimeZoneSidKey, Username, UserPermissionsSupportUser FROM User WHERE Id = :storeSetupImport.Front_Room_User__c];
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01fr', frontUser.Alias);
        System.assertEquals(true, frontUser.Email.containsIgnoreCase('sfdc_deadletter@discounttire.com'));
        System.assertEquals('ISO-8859-1', frontUser.EmailEncodingKey);
        System.assertEquals('en_US', frontUser.LanguageLocaleKey);
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_FrontRm', frontUser.LastName);
        System.assertEquals('en_US', frontUser.LocaleSidKey);
        System.assertEquals('Standard User Clone Profile', frontUser.Profile.Name);
        System.assertEquals('America/Phoenix', frontUser.TimeZoneSidKey);
        System.assertEquals(true, frontUser.Username.containsIgnoreCase(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_frontrm@'));
        System.assertEquals(true, frontUser.UserPermissionsSupportUser);

        //Validate Back Room User
        User backUser = [SELECT Id, Alias, Email, EmailEncodingKey, LanguageLocaleKey, LastName, LocaleSidKey, Profile.Name, TimeZoneSidKey, Username, UserPermissionsSupportUser FROM User WHERE Id = :storeSetupImport.Back_Room_User__c];
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01br', backUser.Alias);
        System.assertEquals(true, backUser.Email.containsIgnoreCase('sfdc_deadletter@discounttire.com'));
        System.assertEquals('ISO-8859-1', backUser.EmailEncodingKey);
        System.assertEquals('en_US', backUser.LanguageLocaleKey);
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_BackRm', backUser.LastName);
        System.assertEquals('en_US', backUser.LocaleSidKey);
        System.assertEquals('Standard User Clone Profile', backUser.Profile.Name);
        System.assertEquals('America/Phoenix', backUser.TimeZoneSidKey);
        System.assertEquals(true, backUser.Username.containsIgnoreCase(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_backrm@'));
        System.assertEquals(true, backUser.UserPermissionsSupportUser);

        //Validate Front Room User Permission Set Assignments
        List<PermissionSetAssignment> frontUserPSAs = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :frontUser.Id AND PermissionSetId IN :autoAssignedFieldServiceResourcePermissionSetIds];
        System.assertEquals(2, frontUserPSAs.size());

        //Validate Back Room User Permission Set Assignments
        List<PermissionSetAssignment> backUserPSAs = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :backUser.Id AND PermissionSetId IN :autoAssignedFieldServiceResourcePermissionSetIds];
        System.assertEquals(2, backUserPSAs.size());
    }

    @IsTest
    static void testStoreSetupUserBatchWithSpaceInStoreID() {
        String storePrefixWithSpace = Appt_StoreSetupTestUtil.STORE_PREFIX + ' ';

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Appt_StoreSetupTestUtil.createPOSTerminalUsers(1, storePrefixWithSpace, storePrefixWithSpace.toLowerCase());
        }

        Appt_StoreSetupTestUtil.createSiteAccounts(1, storePrefixWithSpace);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, storePrefixWithSpace, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        Set<Id> autoAssignedFieldServiceResourcePermissionSetIds = new Set<Id>();
        for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE Label IN :Appt_StoreSetupUtil.getAutoAssignedFieldServiceResourcePermissionSetLabels()]) {
            autoAssignedFieldServiceResourcePermissionSetIds.add(ps.Id);
        }

        Test.startTest();

        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Room_User__c, Front_Room_User__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.User_Creation_Status__c);

        //Validate Front Room User
        User frontUser = [SELECT Id, Alias, Email, EmailEncodingKey, LanguageLocaleKey, LastName, LocaleSidKey, Profile.Name, TimeZoneSidKey, Username, UserPermissionsSupportUser FROM User WHERE Id = :storeSetupImport.Front_Room_User__c];
        System.assertEquals(storePrefixWithSpace + '01fr', frontUser.Alias);
        System.assertEquals(true, frontUser.Email.containsIgnoreCase('sfdc_deadletter@discounttire.com'));
        System.assertEquals('ISO-8859-1', frontUser.EmailEncodingKey);
        System.assertEquals('en_US', frontUser.LanguageLocaleKey);
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_FrontRm', frontUser.LastName);
        System.assertEquals('en_US', frontUser.LocaleSidKey);
        System.assertEquals('Standard User Clone Profile', frontUser.Profile.Name);
        System.assertEquals('America/Phoenix', frontUser.TimeZoneSidKey);
        System.assertEquals(true, frontUser.Username.containsIgnoreCase(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_frontrm@'));
        System.assertEquals(true, frontUser.UserPermissionsSupportUser);

        //Validate Back Room User
        User backUser = [SELECT Id, Alias, Email, EmailEncodingKey, LanguageLocaleKey, LastName, LocaleSidKey, Profile.Name, TimeZoneSidKey, Username, UserPermissionsSupportUser FROM User WHERE Id = :storeSetupImport.Back_Room_User__c];
        System.assertEquals(storePrefixWithSpace + '01br', backUser.Alias);
        System.assertEquals(true, backUser.Email.containsIgnoreCase('sfdc_deadletter@discounttire.com'));
        System.assertEquals('ISO-8859-1', backUser.EmailEncodingKey);
        System.assertEquals('en_US', backUser.LanguageLocaleKey);
        System.assertEquals(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_BackRm', backUser.LastName);
        System.assertEquals('en_US', backUser.LocaleSidKey);
        System.assertEquals('Standard User Clone Profile', backUser.Profile.Name);
        System.assertEquals('America/Phoenix', backUser.TimeZoneSidKey);
        System.assertEquals(true, backUser.Username.containsIgnoreCase(Appt_StoreSetupTestUtil.STORE_PREFIX + '01_backrm@'));
        System.assertEquals(true, backUser.UserPermissionsSupportUser);

        //Validate Front Room User Permission Set Assignments
        List<PermissionSetAssignment> frontUserPSAs = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :frontUser.Id AND PermissionSetId IN :autoAssignedFieldServiceResourcePermissionSetIds];
        System.assertEquals(2, frontUserPSAs.size());

        //Validate Back Room User Permission Set Assignments
        List<PermissionSetAssignment> backUserPSAs = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :backUser.Id AND PermissionSetId IN :autoAssignedFieldServiceResourcePermissionSetIds];
        System.assertEquals(2, backUserPSAs.size());
    }

    @IsTest
    static void testStoreSetupUserBatchWithInvalidStoreID() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Appt_StoreSetupTestUtil.createPOSTerminalUsers(1, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
        }

        Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        String invalidStorePrefix = '_' + Appt_StoreSetupTestUtil.STORE_PREFIX + '_';
        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, invalidStorePrefix, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        Test.startTest();

        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Room_User__c, Front_Room_User__c, User_Creation_Message__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.User_Creation_Status__c);
        System.assertEquals('Front Room User was not found for this Store Setup Import. Please check the Logs for additional details.', storeSetupImport.User_Creation_Message__c);
        System.assertEquals(null, storeSetupImport.Front_Room_User__c);
        System.assertEquals(null, storeSetupImport.Back_Room_User__c);
    }

    @IsTest
    static void testStoreSetupUserBatchWithMissingOperatingHoursRecord() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            Appt_StoreSetupTestUtil.createPOSTerminalUsers(1, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
        }

        Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        storeSetupImports[0].Operating_Hours__c = 'Pacific (M-F 8-6, Sat 8-5) Store Hours';
        update storeSetupImports;

        Test.startTest();

        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Room_User__c, Front_Room_User__c, User_Creation_Message__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.User_Creation_Status__c);
        System.assertEquals('The requested \'Operating Hours\' could not be found. Due to this error, the Front Room User could not be created.', storeSetupImport.User_Creation_Message__c);
        System.assertEquals(null, storeSetupImport.Front_Room_User__c);
        System.assertEquals(null, storeSetupImport.Back_Room_User__c);
    }
}