/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/30/22
 * @description Test class for the Appt_StoreSetupUtil class
 */

@IsTest
private class Appt_StoreSetupUtilTest {

    @IsTest
    static void testGetExpectedFrontUserNameForStoreName() {
        Test.startTest();

        String expectedFrontUserNameForStoreName = Appt_StoreSetupUtil.getExpectedFrontUserNameForStoreName('ABC123');
        System.assertEquals('ABC123_FrontRm', expectedFrontUserNameForStoreName);

        Test.stopTest();
    }

    @IsTest
    static void testGetExpectedBackUserNameForStoreName() {
        Test.startTest();

        String expectedBackUserNameForStoreName = Appt_StoreSetupUtil.getExpectedBackUserNameForStoreName('ABC123');
        System.assertEquals('ABC123_BackRm', expectedBackUserNameForStoreName);

        Test.stopTest();
    }

    @IsTest
    static void testTrackStoreSetupImportUserCreationErrorWithMap() {
        Map<String, String> storeSetupImportIdsToUserErrorsMap = new Map<String, String>();
        String storeSetupImportId = 'storeSetupImportId';
        String errorMessage = 'Error Message 1';

        Test.startTest();

        System.assertEquals(false, storeSetupImportIdsToUserErrorsMap.containsKey(storeSetupImportId));

        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImportId, errorMessage);
        System.assertEquals(true, storeSetupImportIdsToUserErrorsMap.containsKey(storeSetupImportId));
        System.assertEquals(errorMessage, storeSetupImportIdsToUserErrorsMap.get(storeSetupImportId));

        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImportIdsToUserErrorsMap, storeSetupImportId, 'Error Message 2');
        System.assertEquals(true, storeSetupImportIdsToUserErrorsMap.containsKey(storeSetupImportId));
        System.assertEquals(errorMessage, storeSetupImportIdsToUserErrorsMap.get(storeSetupImportId));

        Test.stopTest();
    }

    @IsTest
    static void testTrackStoreSetupImportUserCreationErrorWithStoreSetupImport() {
        Store_Setup_Import__c storeSetupImport = new Store_Setup_Import__c();
        String errorMessage = 'Error Message 1';

        Test.startTest();

        System.assertEquals(false, String.isNotBlank(storeSetupImport.User_Creation_Status__c));
        System.assertEquals(false, String.isNotBlank(storeSetupImport.User_Creation_Message__c));

        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImport, errorMessage);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.User_Creation_Status__c));
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.User_Creation_Status__c);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.User_Creation_Message__c));
        System.assertEquals(errorMessage, storeSetupImport.User_Creation_Message__c);

        Appt_StoreSetupUtil.trackStoreSetupImportUserCreationError(storeSetupImport, 'Error Message 2');
        System.assertEquals(true, String.isNotBlank(storeSetupImport.User_Creation_Status__c));
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.User_Creation_Status__c);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.User_Creation_Message__c));
        System.assertEquals(errorMessage, storeSetupImport.User_Creation_Message__c);

        Test.stopTest();
    }

    @IsTest
    static void testTrackStoreSetupImportStoreCreationError() {
        Store_Setup_Import__c storeSetupImport = new Store_Setup_Import__c();
        String errorMessage = 'Error Message 1';

        Test.startTest();

        System.assertEquals(false, String.isNotBlank(storeSetupImport.Store_Creation_Status__c));
        System.assertEquals(false, String.isNotBlank(storeSetupImport.Store_Creation_Message__c));

        Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, errorMessage);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.Store_Creation_Status__c));
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.Store_Creation_Status__c);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.Store_Creation_Message__c));
        System.assertEquals(errorMessage, storeSetupImport.Store_Creation_Message__c);

        Appt_StoreSetupUtil.trackStoreSetupImportStoreCreationError(storeSetupImport, 'Error Message 2');
        System.assertEquals(true, String.isNotBlank(storeSetupImport.Store_Creation_Status__c));
        System.assertEquals(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR, storeSetupImport.Store_Creation_Status__c);
        System.assertEquals(true, String.isNotBlank(storeSetupImport.Store_Creation_Message__c));
        System.assertEquals(errorMessage, storeSetupImport.Store_Creation_Message__c);

        Test.stopTest();
    }

    @IsTest
    static void testIsStoreSetupImportError() {
        Store_Setup_Import__c storeSetupImport = new Store_Setup_Import__c();
        storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_READY;
        storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_NOT_READY;
        storeSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_NOT_READY;

        Test.startTest();

        System.assertEquals(false, Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport));

        storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
        System.assertEquals(true, Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport));

        storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
        storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
        System.assertEquals(true, Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport));

        storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
        storeSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
        System.assertEquals(true, Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport));

        storeSetupImport.Time_Slot_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_COMPLETED;
        System.assertEquals(false, Appt_StoreSetupUtil.isStoreSetupImportError(storeSetupImport));

        Test.stopTest();
    }

    @IsTest
    static void testGetTimeSlotUniqueKey() {
        String dayOfWeek = 'Friday';
        Time startTime = Time.newInstance(12, 0, 0, 0);
        Time endTime = Time.newInstance(12, 15, 0, 0);

        Test.startTest();

        String expectedTimeSlotUniqueKey = dayOfWeek + '|' + startTime + '|' + endTime;
        System.assertEquals(expectedTimeSlotUniqueKey, Appt_StoreSetupUtil.getTimeSlotUniqueKey(dayOfWeek, startTime, endTime));

        Test.stopTest();
    }
}