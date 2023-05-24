/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/26/22
 * @description Test class for the Appt_StoreSetupServiceTerritoryBatch class
 */

@IsTest
private class Appt_StoreSetupServiceTerritoryBatchTest {

    @TestSetup
    static void setupTest() {
        Appt_StoreSetupTestUtil.createPOSTerminalUsers(1, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
        Appt_StoreSetupTestUtil.createFrontAndBackUsers(1, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
    }

    @IsTest
    static void testStoreSetupServiceTerritoryBatch() {
        List<Account> accounts = Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        String expectedPOSTerminalUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_POS';
        String expectedFrontUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_FrontRm';
        String expectedBackUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_BackRm';

        User posUser = [SELECT Id FROM User WHERE LastName = :expectedPOSTerminalUserName LIMIT 1];
        User frontUser = [SELECT Id FROM User WHERE LastName = :expectedFrontUserName LIMIT 1];
        User backUser = [SELECT Id FROM User WHERE LastName = :expectedBackUserName LIMIT 1];

        //Build Map of Appt Time Slot Capacity Defaults that are setup in Custom Metadata that will be used to validate Appt Time Slot Capacity Front/Back Room Capacities
        Map<String, Appt_Time_Slot_Capacity_Default__mdt> apptTimeSlotCapacityDefaultsMap = new Map<String, Appt_Time_Slot_Capacity_Default__mdt>();
        for (Appt_Time_Slot_Capacity_Default__mdt atscDefault : [SELECT BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, Default_Group_Name__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity_Default__mdt WHERE Default_Group_Name__c = :storeSetupImports[0].Front_Back_Room_Default_Capacity_Group__c]) {
            Time startTime = Time.newInstance(Integer.valueOf(atscDefault.Start_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.Start_Time__c.substring(2, 4)), 0, 0);
            Time endTime = Time.newInstance(Integer.valueOf(atscDefault.End_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.End_Time__c.substring(2, 4)), 0, 0);
            apptTimeSlotCapacityDefaultsMap.put(Appt_StoreSetupUtil.getTimeSlotUniqueKey(atscDefault.Day_of_Week__c, startTime, endTime), atscDefault);
        }

        Test.startTest();

        Appt_StoreSetupServiceTerritoryBatch batch = new Appt_StoreSetupServiceTerritoryBatch(new List<String>{ storeSetupImportId }, new Map<String, String>{ storeSetupImportId => frontUser.Id }, new Map<String, String>{ storeSetupImportId => backUser.Id }, new Map<String, String>(), 'test@invalid.example.com.test');
        Database.executeBatch(batch, 1);
        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Appointment_Work_Type__c, Back_Room_Service_Resource__c, Back_Room_User__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Front_Back_Room_Resource_Type__c, Front_Room_Service_Resource__c, Front_Time_Slot_Configuration__c, Front_Room_User__c, Operating_Hours__c, POS_Terminal_User__c, Scheduling_Policy__c, Service_Territory__c, Store_Creation_Status__c, Store_ID__c, Store_Is_Active__c, Time_Slot_Creation_Status__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.User_Creation_Status__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.Store_Creation_Status__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.Time_Slot_Creation_Status__c);

        //Validate Front Room Service Resource
        ServiceResource frontSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Front_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Front', frontSR.Name);
        System.assertEquals(storeSetupImport.Front_Room_User__c, frontSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, frontSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT, frontSR.Type__c);
        System.assertEquals(true, frontSR.IsActive);

        //Validate Back Room Service Resource
        ServiceResource backSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Back_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Back', backSR.Name);
        System.assertEquals(storeSetupImport.Back_Room_User__c, backSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, backSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK, backSR.Type__c);
        System.assertEquals(true, backSR.IsActive);

        //Validate Service Territory
        ServiceTerritory st = [SELECT Id, IsActive, Name, Appt_Record_Owner__c, Back_Appointment_Work_Type__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Front_Time_Slot_Configuration__c, OperatingHoursId, Scheduling_Policy__c, Site_Account__c  FROM ServiceTerritory WHERE Id = :storeSetupImport.Service_Territory__c];
        System.assertEquals(storeSetupImport.Store_ID__c, st.Name);
        System.assertEquals(storeSetupImport.Store_Is_Active__c, st.IsActive);
        System.assertEquals(sp.Id, st.Scheduling_Policy__c);
        System.assertEquals(accounts[0].Id, st.Site_Account__c);
        System.assertEquals(bucketCapacityOH.Id, st.Front_Time_Slot_Configuration__c);
        System.assertEquals(bucketCapacityOH.Id, st.Back_Time_Slot_Configuration__c);
        System.assertEquals(storeHoursOH.Id, st.OperatingHoursId);
        System.assertEquals(wt.Id, st.Front_Appointment_Work_Type__c);
        System.assertEquals(wt.Id, st.Back_Appointment_Work_Type__c);
        System.assertEquals(posUser.Id, st.Appt_Record_Owner__c);

        //Validate Front Room Service Territory Member
        ServiceTerritoryMember frontSTM = [SELECT Id, EffectiveStartDate FROM ServiceTerritoryMember WHERE ServiceResourceId = :storeSetupImport.Front_Room_Service_Resource__c AND ServiceTerritoryId = :storeSetupImport.Service_Territory__c LIMIT 1];
        System.assertNotEquals(null, frontSTM.EffectiveStartDate);

        //Validate Back Room Service Territory Member
        ServiceTerritoryMember backSTM = [SELECT Id, EffectiveStartDate FROM ServiceTerritoryMember WHERE ServiceResourceId = :storeSetupImport.Back_Room_Service_Resource__c AND ServiceTerritoryId = :storeSetupImport.Service_Territory__c LIMIT 1];
        System.assertNotEquals(null, backSTM.EffectiveStartDate);

        //Validate Appt Time Slot Capacities
        List<Appt_Time_Slot_Capacity__c> apptTimeSlotCapacities = [SELECT Id, BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity__c WHERE Service_Territory__c = :st.Id];
        System.assertEquals(236, apptTimeSlotCapacities.size());
        for (Appt_Time_Slot_Capacity__c atsc : apptTimeSlotCapacities) {
            String timeSlotUniqueKey = Appt_StoreSetupUtil.getTimeSlotUniqueKey(atsc.Day_of_Week__c, atsc.Start_Time__c, atsc.End_Time__c);
            if (apptTimeSlotCapacityDefaultsMap.containsKey(timeSlotUniqueKey)) {
                Appt_Time_Slot_Capacity_Default__mdt atscDefault = apptTimeSlotCapacityDefaultsMap.get(timeSlotUniqueKey);
                System.assertEquals(atscDefault.BSF_Capacity__c, atsc.BSF_Capacity__c);
                System.assertEquals(atscDefault.BSR_Capacity__c, atsc.BSR_Capacity__c);
                System.assertEquals(atscDefault.BWF_Capacity__c, atsc.BWF_Capacity__c);
                System.assertEquals(atscDefault.BWR_Capacity__c, atsc.BWR_Capacity__c);
                System.assertEquals(atscDefault.FSF_Capacity__c, atsc.FSF_Capacity__c);
                System.assertEquals(atscDefault.FSR_Capacity__c, atsc.FSR_Capacity__c);
                System.assertEquals(atscDefault.FWF_Capacity__c, atsc.FWF_Capacity__c);
                System.assertEquals(atscDefault.FWR_Capacity__c, atsc.FWR_Capacity__c);
            } else {
                System.assertEquals(0, atsc.BSF_Capacity__c);
                System.assertEquals(0, atsc.BSR_Capacity__c);
                System.assertEquals(0, atsc.BWF_Capacity__c);
                System.assertEquals(0, atsc.BWR_Capacity__c);
                System.assertEquals(0, atsc.FSF_Capacity__c);
                System.assertEquals(0, atsc.FSR_Capacity__c);
                System.assertEquals(0, atsc.FWF_Capacity__c);
                System.assertEquals(0, atsc.FWR_Capacity__c);
            }
        }

        //Validate Front Room Appt Time Slots
        List<Appt_Time_Slot__c> frontTimeSlots = [SELECT Id FROM Appt_Time_Slot__c WHERE Service_Territory__c = :st.Id AND Type__c = :Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT];
        System.assertEquals(false, frontTimeSlots.isEmpty());

        //Validate Back Room Appt Time Slots
        List<Appt_Time_Slot__c> backTimeSlots = [SELECT Id FROM Appt_Time_Slot__c WHERE Service_Territory__c = :st.Id AND Type__c = :Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK];
        System.assertEquals(false, backTimeSlots.isEmpty());
    }

    @IsTest
    static void testStoreSetupServiceTerritoryBatchNoPOSTerminalUserOnStoreSetupImport() {
        List<Account> accounts = Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        storeSetupImports[0].POS_Terminal_User__c = null;
        update storeSetupImports[0];

        String expectedPOSTerminalUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_POS';
        String expectedFrontUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_FrontRm';
        String expectedBackUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_BackRm';

        User posUser = [SELECT Id, LastName FROM User WHERE LastName = :expectedPOSTerminalUserName LIMIT 1];
        posUser.LastName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01';
        update posUser;

        User frontUser = [SELECT Id FROM User WHERE LastName = :expectedFrontUserName LIMIT 1];
        User backUser = [SELECT Id FROM User WHERE LastName = :expectedBackUserName LIMIT 1];

        //Build Map of Appt Time Slot Capacity Defaults that are setup in Custom Metadata that will be used to validate Appt Time Slot Capacity Front/Back Room Capacities
        Map<String, Appt_Time_Slot_Capacity_Default__mdt> apptTimeSlotCapacityDefaultsMap = new Map<String, Appt_Time_Slot_Capacity_Default__mdt>();
        for (Appt_Time_Slot_Capacity_Default__mdt atscDefault : [SELECT BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, Default_Group_Name__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity_Default__mdt WHERE Default_Group_Name__c = :storeSetupImports[0].Front_Back_Room_Default_Capacity_Group__c]) {
            Time startTime = Time.newInstance(Integer.valueOf(atscDefault.Start_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.Start_Time__c.substring(2, 4)), 0, 0);
            Time endTime = Time.newInstance(Integer.valueOf(atscDefault.End_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.End_Time__c.substring(2, 4)), 0, 0);
            apptTimeSlotCapacityDefaultsMap.put(Appt_StoreSetupUtil.getTimeSlotUniqueKey(atscDefault.Day_of_Week__c, startTime, endTime), atscDefault);
        }

        Test.startTest();

        Appt_StoreSetupServiceTerritoryBatch batch = new Appt_StoreSetupServiceTerritoryBatch(new List<String>{ storeSetupImportId }, new Map<String, String>{ storeSetupImportId => frontUser.Id }, new Map<String, String>{ storeSetupImportId => backUser.Id }, new Map<String, String>(), 'test@invalid.example.com.test');
        Database.executeBatch(batch, 1);
        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Appointment_Work_Type__c, Back_Room_Service_Resource__c, Back_Room_User__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Front_Back_Room_Resource_Type__c, Front_Room_Service_Resource__c, Front_Time_Slot_Configuration__c, Front_Room_User__c, Operating_Hours__c, POS_Terminal_User__c, Scheduling_Policy__c, Service_Territory__c, Store_Creation_Status__c, Store_ID__c, Store_Is_Active__c, Time_Slot_Creation_Status__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.User_Creation_Status__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.Store_Creation_Status__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.Time_Slot_Creation_Status__c);

        //Validate Front Room Service Resource
        ServiceResource frontSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Front_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Front', frontSR.Name);
        System.assertEquals(storeSetupImport.Front_Room_User__c, frontSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, frontSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT, frontSR.Type__c);
        System.assertEquals(true, frontSR.IsActive);

        //Validate Back Room Service Resource
        ServiceResource backSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Back_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Back', backSR.Name);
        System.assertEquals(storeSetupImport.Back_Room_User__c, backSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, backSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK, backSR.Type__c);
        System.assertEquals(true, backSR.IsActive);

        //Validate Service Territory
        ServiceTerritory st = [SELECT Id, IsActive, Name, Appt_Record_Owner__c, Back_Appointment_Work_Type__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Front_Time_Slot_Configuration__c, OperatingHoursId, Scheduling_Policy__c, Site_Account__c  FROM ServiceTerritory WHERE Id = :storeSetupImport.Service_Territory__c];
        System.assertEquals(storeSetupImport.Store_ID__c, st.Name);
        System.assertEquals(storeSetupImport.Store_Is_Active__c, st.IsActive);
        System.assertEquals(sp.Id, st.Scheduling_Policy__c);
        System.assertEquals(accounts[0].Id, st.Site_Account__c);
        System.assertEquals(bucketCapacityOH.Id, st.Front_Time_Slot_Configuration__c);
        System.assertEquals(bucketCapacityOH.Id, st.Back_Time_Slot_Configuration__c);
        System.assertEquals(storeHoursOH.Id, st.OperatingHoursId);
        System.assertEquals(wt.Id, st.Front_Appointment_Work_Type__c);
        System.assertEquals(wt.Id, st.Back_Appointment_Work_Type__c);
        System.assertEquals(posUser.Id, st.Appt_Record_Owner__c);

        //Validate Front Room Service Territory Member
        ServiceTerritoryMember frontSTM = [SELECT Id, EffectiveStartDate FROM ServiceTerritoryMember WHERE ServiceResourceId = :storeSetupImport.Front_Room_Service_Resource__c AND ServiceTerritoryId = :storeSetupImport.Service_Territory__c LIMIT 1];
        System.assertNotEquals(null, frontSTM.EffectiveStartDate);

        //Validate Back Room Service Territory Member
        ServiceTerritoryMember backSTM = [SELECT Id, EffectiveStartDate FROM ServiceTerritoryMember WHERE ServiceResourceId = :storeSetupImport.Back_Room_Service_Resource__c AND ServiceTerritoryId = :storeSetupImport.Service_Territory__c LIMIT 1];
        System.assertNotEquals(null, backSTM.EffectiveStartDate);

        //Validate Appt Time Slot Capacities
        List<Appt_Time_Slot_Capacity__c> apptTimeSlotCapacities = [SELECT Id, BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity__c WHERE Service_Territory__c = :st.Id];
        System.assertEquals(236, apptTimeSlotCapacities.size());
        for (Appt_Time_Slot_Capacity__c atsc : apptTimeSlotCapacities) {
            String timeSlotUniqueKey = Appt_StoreSetupUtil.getTimeSlotUniqueKey(atsc.Day_of_Week__c, atsc.Start_Time__c, atsc.End_Time__c);
            if (apptTimeSlotCapacityDefaultsMap.containsKey(timeSlotUniqueKey)) {
                Appt_Time_Slot_Capacity_Default__mdt atscDefault = apptTimeSlotCapacityDefaultsMap.get(timeSlotUniqueKey);
                System.assertEquals(atscDefault.BSF_Capacity__c, atsc.BSF_Capacity__c);
                System.assertEquals(atscDefault.BSR_Capacity__c, atsc.BSR_Capacity__c);
                System.assertEquals(atscDefault.BWF_Capacity__c, atsc.BWF_Capacity__c);
                System.assertEquals(atscDefault.BWR_Capacity__c, atsc.BWR_Capacity__c);
                System.assertEquals(atscDefault.FSF_Capacity__c, atsc.FSF_Capacity__c);
                System.assertEquals(atscDefault.FSR_Capacity__c, atsc.FSR_Capacity__c);
                System.assertEquals(atscDefault.FWF_Capacity__c, atsc.FWF_Capacity__c);
                System.assertEquals(atscDefault.FWR_Capacity__c, atsc.FWR_Capacity__c);
            } else {
                System.assertEquals(0, atsc.BSF_Capacity__c);
                System.assertEquals(0, atsc.BSR_Capacity__c);
                System.assertEquals(0, atsc.BWF_Capacity__c);
                System.assertEquals(0, atsc.BWR_Capacity__c);
                System.assertEquals(0, atsc.FSF_Capacity__c);
                System.assertEquals(0, atsc.FSR_Capacity__c);
                System.assertEquals(0, atsc.FWF_Capacity__c);
                System.assertEquals(0, atsc.FWR_Capacity__c);
            }
        }

        //Validate Front Room Appt Time Slots
        List<Appt_Time_Slot__c> frontTimeSlots = [SELECT Id FROM Appt_Time_Slot__c WHERE Service_Territory__c = :st.Id AND Type__c = :Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT];
        System.assertEquals(false, frontTimeSlots.isEmpty());

        //Validate Back Room Appt Time Slots
        List<Appt_Time_Slot__c> backTimeSlots = [SELECT Id FROM Appt_Time_Slot__c WHERE Service_Territory__c = :st.Id AND Type__c = :Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK];
        System.assertEquals(false, backTimeSlots.isEmpty());
    }

    @IsTest
    static void testStoreSetupServiceTerritoryBatchInvalidPOSTerminalUser() {
        Appt_StoreSetupTestUtil.createSiteAccounts(1, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_STORE_HOURS);
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', Appt_ConstantValues.OPERATING_HOURS_TYPE_CAPACITY);

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(1, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);
        String storeSetupImportId = storeSetupImports[0].Id;

        storeSetupImports[0].POS_Terminal_User__c = 'INVALID';
        update storeSetupImports[0];

        String expectedFrontUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_FrontRm';
        String expectedBackUserName = Appt_StoreSetupTestUtil.STORE_PREFIX + '01_BackRm';

        User frontUser = [SELECT Id FROM User WHERE LastName = :expectedFrontUserName LIMIT 1];
        User backUser = [SELECT Id FROM User WHERE LastName = :expectedBackUserName LIMIT 1];

        //Build Map of Appt Time Slot Capacity Defaults that are setup in Custom Metadata that will be used to validate Appt Time Slot Capacity Front/Back Room Capacities
        Map<String, Appt_Time_Slot_Capacity_Default__mdt> apptTimeSlotCapacityDefaultsMap = new Map<String, Appt_Time_Slot_Capacity_Default__mdt>();
        for (Appt_Time_Slot_Capacity_Default__mdt atscDefault : [SELECT BSF_Capacity__c, BSR_Capacity__c, BWF_Capacity__c, BWR_Capacity__c, Day_of_Week__c, Default_Group_Name__c, End_Time__c, FSF_Capacity__c, FSR_Capacity__c, FWF_Capacity__c, FWR_Capacity__c, Start_Time__c FROM Appt_Time_Slot_Capacity_Default__mdt WHERE Default_Group_Name__c = :storeSetupImports[0].Front_Back_Room_Default_Capacity_Group__c]) {
            Time startTime = Time.newInstance(Integer.valueOf(atscDefault.Start_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.Start_Time__c.substring(2, 4)), 0, 0);
            Time endTime = Time.newInstance(Integer.valueOf(atscDefault.End_Time__c.substring(0, 2)), Integer.valueOf(atscDefault.End_Time__c.substring(2, 4)), 0, 0);
            apptTimeSlotCapacityDefaultsMap.put(Appt_StoreSetupUtil.getTimeSlotUniqueKey(atscDefault.Day_of_Week__c, startTime, endTime), atscDefault);
        }

        Test.startTest();

        Appt_StoreSetupServiceTerritoryBatch batch = new Appt_StoreSetupServiceTerritoryBatch(new List<String>{ storeSetupImportId }, new Map<String, String>{ storeSetupImportId => frontUser.Id }, new Map<String, String>{ storeSetupImportId => backUser.Id }, new Map<String, String>(), 'test@invalid.example.com.test');
        Database.executeBatch(batch, 1);
        Appt_StoreSetupUserBatch.startStoreSetupUserBatch(new List<String>{ storeSetupImportId }, 'test@invalid.example.com.test');

        Test.stopTest();

        //Validate Store Setup Import
        Store_Setup_Import__c storeSetupImport = [SELECT Id, Back_Appointment_Work_Type__c, Back_Room_Service_Resource__c, Back_Room_User__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Front_Back_Room_Resource_Type__c, Front_Room_Service_Resource__c, Front_Time_Slot_Configuration__c, Front_Room_User__c, Operating_Hours__c, POS_Terminal_User__c, Scheduling_Policy__c, Service_Territory__c, Store_Creation_Message__c, Store_Creation_Status__c, Store_ID__c, Store_Is_Active__c, Time_Slot_Creation_Status__c, User_Creation_Status__c FROM Store_Setup_Import__c WHERE Id = :storeSetupImportId];
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED, storeSetupImport.User_Creation_Status__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.Store_Creation_Status__c);
        System.assertEquals('The POS Terminal User for this Store Setup Import could not be found. Please confirm there is an existing User with the "POS Store Terminal" Profile and the same Name as the given Store ID or POS Terminal User (if not blank).', storeSetupImport.Store_Creation_Message__c);
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_NOT_READY, storeSetupImport.Time_Slot_Creation_Status__c);

        //Validate Front Room Service Resource
        ServiceResource frontSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Front_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Front', frontSR.Name);
        System.assertEquals(storeSetupImport.Front_Room_User__c, frontSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, frontSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_FRONT, frontSR.Type__c);
        System.assertEquals(true, frontSR.IsActive);

        //Validate Back Room Service Resource
        ServiceResource backSR = [SELECT Id, IsActive, Name, RelatedRecordId, ResourceType, Type__c FROM ServiceResource WHERE Id = :storeSetupImport.Back_Room_Service_Resource__c];
        System.assertEquals(storeSetupImport.Store_ID__c + ' Back', backSR.Name);
        System.assertEquals(storeSetupImport.Back_Room_User__c, backSR.RelatedRecordId);
        System.assertEquals(storeSetupImport.Front_Back_Room_Resource_Type__c, backSR.ResourceType);
        System.assertEquals(Appt_ConstantValues.SERVICE_RESOURCE_TYPE_BACK, backSR.Type__c);
        System.assertEquals(true, backSR.IsActive);

        //Validate Service Territory was not created
        List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory];
        System.assertEquals(0, serviceTerritories.size());
        System.assertEquals(null, storeSetupImport.Service_Territory__c);
    }
}