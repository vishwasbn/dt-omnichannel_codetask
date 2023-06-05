/**
 * @author Mitchell Corbin (mitchell.corbin@appsassociates.com)
 * @date 5/30/22
 * @description Utility class used to assist with the Automated Store Setup Batch Processes
 */

public class Appt_StoreSetupUtil {
    public static final String LOG_IDENTIFIER = 'Appointments';

    public static final String FRONT_BACK_ROOM_USER_NAME_POSTFIX_SEPARATOR = '_';
    public static final String FRONT_ROOM_USER_NAME_POSTFIX = 'FrontRm';
    public static final String BACK_ROOM_USER_NAME_POSTFIX = 'BackRm';

    //Method used to determine the expected Front Room User's Name based on the given Store Name
    public static String getExpectedFrontUserNameForStoreName(String storeName) {
        return storeName + FRONT_BACK_ROOM_USER_NAME_POSTFIX_SEPARATOR + FRONT_ROOM_USER_NAME_POSTFIX;
    }

    //Method used to return the Labels of the Field Service Resource Permission Sets that are auto-assigned when Front/Back Users are created
    public static Set<String> getAutoAssignedFieldServiceResourcePermissionSetLabels() {
        return new Set<String>{ 'Field Service Resource License', 'Field Service Resource Permissions' };
    }

    //Method used to determine the expected Back Room User's Name based on the given Store Name
    public static String getExpectedBackUserNameForStoreName(String storeName) {
        return storeName + FRONT_BACK_ROOM_USER_NAME_POSTFIX_SEPARATOR + BACK_ROOM_USER_NAME_POSTFIX;
    }

    //Overloaded method used to track User Creation Errors in the passed in Map
    public static void trackStoreSetupImportUserCreationError(Map<String, String> storeSetupImportIdsToUserErrorsMap, String storeSetupImportId, String errorMessage) {
        if (!storeSetupImportIdsToUserErrorsMap.containsKey(storeSetupImportId)) {
            storeSetupImportIdsToUserErrorsMap.put(storeSetupImportId, errorMessage);
        }
    }

    //Overloaded method used to track User Creation Errors in the passed in Store Setup Import
    public static void trackStoreSetupImportUserCreationError(Store_Setup_Import__c storeSetupImport, String errorMessage) {
        storeSetupImport.User_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
        if (String.isBlank(storeSetupImport.User_Creation_Message__c)) {
            storeSetupImport.User_Creation_Message__c = errorMessage;
        }
    }

    //Overloaded method used to track Store Creation Errors in the passed in Store Setup Import
    public static void trackStoreSetupImportStoreCreationError(Store_Setup_Import__c storeSetupImport, String errorMessage) {
        storeSetupImport.Store_Creation_Status__c = Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR;
        if (String.isBlank(storeSetupImport.Store_Creation_Message__c)) {
            storeSetupImport.Store_Creation_Message__c = errorMessage;
        }
    }

    //Method used to check if an Error occurred on the passed in Store Setup Import
    public static Boolean isStoreSetupImportError(Store_Setup_Import__c storeSetupImport) {
        Boolean isUserCreationError = String.isNotBlank(storeSetupImport.User_Creation_Status__c) && storeSetupImport.User_Creation_Status__c.containsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR);
        Boolean isStoreCreationError = String.isNotBlank(storeSetupImport.Store_Creation_Status__c) && storeSetupImport.Store_Creation_Status__c.containsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR);
        Boolean isTimeSlotCreationError = String.isNotBlank(storeSetupImport.Time_Slot_Creation_Status__c) && storeSetupImport.Time_Slot_Creation_Status__c.containsIgnoreCase(Appt_ConstantValues.STORE_SETUP_IMPORT_STATUS_ERROR);
        return (isUserCreationError || isStoreCreationError || isTimeSlotCreationError);
    }

    //Method used to generate a unique key for a specific Time Slot in a "DayOfWeek|StartTime|EndTime" format
    public static String getTimeSlotUniqueKey(String dayOfWeek, Time startTime, Time endTime) {
        return dayOfWeek + '|' + startTime + '|' + endTime;
    }
}