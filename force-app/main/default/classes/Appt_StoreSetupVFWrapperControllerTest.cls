/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/26/22
 * @description Test class for the Appt_StoreSetupVFWrapperController class
 */

@IsTest
private class Appt_StoreSetupVFWrapperControllerTest {

    @TestSetup
    static void setupTest() {
        Appt_StoreSetupTestUtil.createPOSTerminalUsers(10, Appt_StoreSetupTestUtil.STORE_PREFIX, Appt_StoreSetupTestUtil.STORE_PREFIX.toLowerCase());
    }

    @IsTest
    static void testConstructor() {
        Appt_StoreSetupTestUtil.createSiteAccounts(10, Appt_StoreSetupTestUtil.STORE_PREFIX);
        FSL__Scheduling_Policy__c sp = Appt_StoreSetupTestUtil.createSchedulingPolicy('Appointment Policy');
        WorkType wt = Appt_StoreSetupTestUtil.createWorkType('15 Minute Appointment', 15, 'Minutes');
        OperatingHours storeHoursOH = Appt_StoreSetupTestUtil.createOperatingHours('Arizona (M-F 8-6, Sat 8-5) Store Hours', 'America/Phoenix', 'Store Hours');
        OperatingHours bucketCapacityOH = Appt_StoreSetupTestUtil.createOperatingHours('15 Minute Time Slots 4 Bucket Capacity', 'America/Phoenix', 'Bucket Capacity');

        List<Store_Setup_Import__c> storeSetupImports = Appt_StoreSetupTestUtil.createStoreSetupImports(10, Appt_StoreSetupTestUtil.STORE_PREFIX, storeHoursOH, bucketCapacityOH, sp, wt);

        Test.startTest();

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(storeSetupImports);
        ssc.setSelected(storeSetupImports);

        Appt_StoreSetupVFWrapperController con = new Appt_StoreSetupVFWrapperController(ssc);
        System.assertEquals(true, String.isNotBlank(con.currentUserEmail));
        System.assertEquals(true, String.isNotBlank(con.selectedStoreSetupImportIdsString));

        Test.stopTest();
    }
}