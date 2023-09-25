public class Appt_ConstantValues {
    
    public static final String CUSTOMER_TYPE_FLEET = 'Fleet';
    public static final String CUSTOMER_TYPE_RETAIL = 'Retail';

    public static final String RESPONSE_STATUS_SUCCESS = 'Success';
    public static final String RESPONSE_STATUS_ERROR = 'Error';
    public static final String RESPONSE_ERROR_STATUSCODE_BAD_REQUEST = '400';
    public static final String RESPONSE_ERROR_STATUSCODE_NOT_FOUND = '404';
    public static final String RESPONSE_ERROR_STATUSCODE_NOT_AVAILABLE = '428';
    public static final String RESPONSE_ERROR_STATUSCODE_SYSTEM_ERROR = '500';

    public static final String SCHEDULING_POLICY_NAME = 'Appointment Policy';

    public static final String WORK_TYPE_APPOINTMENT = 'Appointment';
    public static final String WORK_TYPE_TYPE_FRONT = 'Front';
    public static final String WORK_TYPE_TYPE_BACK = 'Back';
    public static final String WORK_TYPE_TYPE_BOTH = 'Both';
    public static final Integer WORK_TYPE_DURATION_FRONT_DEFAULT = 20;
    public static final Integer WORK_TYPE_DURATION_BACK_DEFAULT = 20;
    public static final String WORK_ORDER_DURATION_TYPE = 'Minutes';

    public static final String WORKORDER_ORDERTYPE_INV = 'Invoice';
    public static final String WORKORDER_ORDERTYPE_QUO = 'Quote';
    public static final String WORKORDER_ORDERTYPE_LAY = 'Layaway';
    public static final String WORKORDER_ORDERTYPE_BOPIS = 'BOPIS';
    public static final String WORKORDER_ORDERTYPE_ROPIS = 'ROPIS';
    public static final String WORKORDER_ORDERTYPE_SERVICE_APPT = 'ServiceAppointment';
    public static final Set<String> WORKORDER_ORDER_TYPES_FOR_HYBRISNUMBER=new Set<String>{WORKORDER_ORDERTYPE_BOPIS,WORKORDER_ORDERTYPE_ROPIS, WORKORDER_ORDERTYPE_SERVICE_APPT };
 
        
    public static final String SERVICE_RESOURCE_TYPE_FRONT = 'Front Room';
    public static final String SERVICE_RESOURCE_TYPE_BACK = 'Back Room';

    public static final String SERVICE_APPOINTMENT_ACTIVITY_TYPE_FRONT = 'Front Room';
    public static final String SERVICE_APPOINTMENT_ACTIVITY_TYPE_BACK = 'Back Room';

    public static final String APPT_TIME_SLOT_TYPE_FRONT = 'Front Room';
    public static final String APPT_TIME_SLOT_TYPE_BACK = 'Back Room';

    public static final String APPOINTMENT_SOURCE_WEB = 'WEB';
    public static final String APPOINTMENT_SOURCE_POS = 'POS';
    public static final String APPOINTMENT_SOURCE_CSR = 'CSR';
    public static final String APPOINTMENT_SOURCE_STORE = 'STORE';
    public static final String APPOINTMENT_SOURCE_SMS = 'SMS';
    public static final String APPOINTMENT_SOURCE_FILE = 'FILE';
    public static final String APPOINTMENT_SOURCE_STORE_CHAR = 'S';
    public static final String APPOINTMENT_SOURCE_WEB_CHAR = 'W';
    public static final String APPOINTMENT_SOURCE_CUSTOMER_RETAIL_CHAR = 'R';
    public static final String APPOINTMENT_SOURCE_CUSTOMER_FLEET_CHAR = 'F';
    public static final String APPOINTMENT_TYPE_FRONT_CHAR = 'F';
    public static final String APPOINTMENT_TYPE_BACK_CHAR = 'B';

    public static final String SERVICE_APPOINTMENT_STATUS_PENDING = 'Pending';
    public static final String SERVICE_APPOINTMENT_STATUS_SCHEDULED = 'Scheduled';
    public static final String SERVICE_APPOINTMENT_STATUS_CONFIRMED = 'Confirmed';
    public static final String SERVICE_APPOINTMENT_STATUS_IN_PROGRESS = 'In Progress';
    public static final String SERVICE_APPOINTMENT_STATUS_MISSED = 'Missed';
    public static final String SERVICE_APPOINTMENT_STATUS_COMPLETED = 'Completed';
    public static final String SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD = 'Canceled Hold';
    public static final String SERVICE_APPOINTMENT_STATUS_CANCELED = 'Canceled';

    public static final String APPOINTMENT_SETTING_MAX_SLOTS_TO_QUERY = 'Max_Slots_to_Query';
    public static final String APPOINTMENT_SETTING_WEB_APPOINTMENT_LEAD_TIME = 'Appointment_Lead_Time_Web';
    public static final String APPOINTMENT_SETTING_NUMBER_DAYS_APPT_TIME_SLOTS = 'Days_in_Future_Generate_Appt_Time_Slots';
    public static final String APPOINTMENT_SETTING_USER_NATIVE_FSL_AVAILABILITY = 'Use_Native_FSL_Availability';
    public static final String APPOINTMENT_SETTING_SLOT_GENERATOR_CRONEXP = 'Time_to_Run_Batch_Generate_Slots';
    public static final String APPOINTMENT_SETTING_SLOT_GENERATOR_CRONEXP_MINUTES = 'Minutes_to_Run_Batch_Generate_Slots';
    public static final String APPOINTMENT_SETTING_SLOT_GENERATOR_NUMBER_OF_STORES_PER_BATCH = 'Slot_Gen_Number_of_Store_Per_Batch';
    public static final String APPOINTMENT_SETTING_SLOT_GENERATOR_MAX_NUMBER_OF_SLOTS_TO_DELETE = 'Slot_Gen_Num_Del_per_Job';
    public static final String APPOINTMENT_SETTING_AUTOMATED_FRONT_BACK_USERNAME_DOMAIN = 'Automated_Front_Back_Username_Domain';
    public static final String APPOINTMENT_SETTING_GENERATE_CLEANUP_APPT_TIME_SLOTS_BATCH_SIZE = 'GenerateCleanupApptTimeSlots_Batch_Size';
    public static final String APPOINTMENT_SETTING_STORE_SETUP_SERVICE_TERRITORY_BATCH_SIZE = 'StoreSetupServiceTerritory_Batch_Size';
    public static final String APPOINTMENT_SETTING_STORE_SETUP_USER_BATCH_SIZE = 'StoreSetupUser_Batch_Size';

    public static final String OPERATING_HOURS_TYPE_STORE_HOURS = 'Store Hours';
    public static final String OPERATING_HOURS_TYPE_CAPACITY = 'Bucket Capacity';

    public static final String INTEGRATION_SETTING_SYSTEM_APPOINTMENT = 'APPT';
    public static final String INTEGRATION_SETTING_INVOICE_DETAILS_URL = 'Invoice_Details_Url';
    public static final String INTEGRATION_SETTING_INVENTORY_URL = 'Inventory_Url';
    public static final String INTEGRATION_SETTING_DT_SOURCE_SYSTEM = 'dtSourceSystem';
    public static final String INTEGRATION_SETTING_DT_SOURCE_SUBSYSTEM = 'dtSourceSubsystem';
    public static final String INTEGRATION_SETTING_DT_REQUEST_IDENTIFIER = 'dtRequestIdentifier';

    public static final Integer INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER = 1;
    public static final String INVOICE_ID_TYPE_HYBRIS_ORDER_NUMBER_PARAM_NAME = 'hybrisOrderNumber';
    public static final Integer INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER = 2;
    public static final String INVOICE_ID_TYPE_LEGACY_ORDER_NUMBER_PARAM_NAME = 'legacyOrderNumber';
    public static final Integer INVOICE_ID_TYPE_INVOICE_NUMBER = 3;
    public static final String INVOICE_ID_TYPE_INVOICE_NUMBER_PARAM_NAME = 'invoiceNumber';
    public static final Integer INVOICE_ID_TYPE_LAYAWAY_NUMBER = 4;
    public static final String INVOICE_ID_TYPE_LAYAWAY_NUMBER_PARAM_NAME = 'layawayNumber';
    public static final Integer INVOICE_ID_TYPE_QUOTE_NUMBER = 5;
    public static final String INVOICE_ID_TYPE_QUOTE_NUMBER_PARAM_NAME = 'quoteNumber';

    public static final String APPOINTMENT_IMPORT_STATUS_PENDING = 'Pending';
    public static final String APPOINTMENT_IMPORT_STATUS_IN_PROGRESS = 'In Progress'; //no longer used
    public static final String APPOINTMENT_IMPORT_STATUS_IMPORTED = 'Imported';
    public static final String APPOINTMENT_IMPORT_STATUS_ERROR = 'Error';

    public static final String IMPORT_APPOINTMENT_STATUS_CODE_COMPLETED = 'C';
    public static final String IMPORT_APPOINTMENT_STATUS_CODE_CANCELED = 'D';
    public static final String IMPORT_APPOINTMENT_STATUS_CODE_MISSED = 'M';
    public static final String IMPORT_APPOINTMENT_ORDER_TYPE_DEFAULT = 'ServiceAppointment';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_QUO = 'QUO';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_QUO = 'Quote';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_WEB = 'WEB';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_WEB = 'ROPIS';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_LAY = 'LAY';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_LAY = 'Layaway';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_BOP = 'BOP';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_BOP = 'BOPIS';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_INV = 'INV';
    public static final String IMPORT_APPOINTMENT_FORMTYPE_TO_ORDERTYPE_MAP_INV = 'Invoice';

    public static final String STORE_SETUP_IMPORT_STATUS_NOT_READY = 'Not Ready';
    public static final String STORE_SETUP_IMPORT_STATUS_READY = 'Ready';
    public static final String STORE_SETUP_IMPORT_STATUS_COMPLETED = 'Completed';
    public static final String STORE_SETUP_IMPORT_STATUS_ERROR = 'Error';

    public static final String NOTIFICATION_APPT_SCHEDULED = 'APPT_SCHEDULED';
    public static final String NOTIFICATION_APPT_RESCHEDULED = 'APPT_RESCHEDULED';
    public static final String NOTIFICATION_APPT_CANCELLED = 'APPT_CANCELLED';
    public static final String NOTIFICATION_APPT_REMINDER = 'APPT_REMINDER';
    public static final String NOTIFICATION_APPT_NOW = 'APPT_NOW';
    public static final String NOTIFICATION_APPT_LINK_RESCHEDULE = 'APPT_LINK_RESCHEDULE';
    public static final String NOTIFICATION_APPT_LINK_CANCEL = 'APPT_LINK_CANCEL';
    public static final String NOTIFICATION_APPT_LINK_SCHEDULE_NEW = 'APPT_LINK_SCHEDULE_NEW';
    public static final String NOTIFICATION_APPT_CONFIRMED = 'APPT_CONFIRMED';
    public static final String NOTIFICATION_JT_REMINDER = 'JT_REMINDER';
    public static final String NOTIFICATION_STATUS_PENDING = 'Pending';
    public static final String NOTIFICATION_STATUS_SUCCESS= 'Success';
    public static final String NOTIFICATION_STATUS_FAILURE = 'Failure';
    public static final String NOTIFICATION_STATUS_INVAILD_ORDER_NUMBER = 'Invalid Order Number';
    public static final String NOTIFICATION_STATUS_INVALID_DATA = 'Invalid Data';
    public static final Set<String> NOTIFICATION_VALID_VALUES = new Set<String>{ NOTIFICATION_APPT_SCHEDULED,NOTIFICATION_APPT_RESCHEDULED,NOTIFICATION_APPT_CANCELLED,NOTIFICATION_APPT_REMINDER,NOTIFICATION_APPT_NOW,NOTIFICATION_APPT_LINK_RESCHEDULE,NOTIFICATION_APPT_LINK_CANCEL,NOTIFICATION_APPT_LINK_SCHEDULE_NEW,NOTIFICATION_APPT_CONFIRMED, NOTIFICATION_JT_REMINDER };
    public static final Set<String> NOTIFICATION_INITIAL_SMS_VALUES = new Set<String>{ NOTIFICATION_APPT_SCHEDULED,NOTIFICATION_APPT_RESCHEDULED,NOTIFICATION_APPT_CANCELLED,NOTIFICATION_APPT_REMINDER,NOTIFICATION_APPT_NOW, NOTIFICATION_JT_REMINDER};
    public static final Set<String> NOTIFICATION_REPLY_SMS_VALUES = new Set<String>{ NOTIFICATION_APPT_LINK_RESCHEDULE,NOTIFICATION_APPT_LINK_CANCEL,NOTIFICATION_APPT_LINK_SCHEDULE_NEW,NOTIFICATION_APPT_CONFIRMED };
    public static final Set<String> NOTIFICATION_INITAIL_EMAIL_VALUES = new Set<String>{NOTIFICATION_APPT_SCHEDULED,NOTIFICATION_APPT_RESCHEDULED,NOTIFICATION_APPT_CANCELLED,NOTIFICATION_APPT_REMINDER};
    public static final String STORAGE_TYPE_ARCHIVED = 'Archived';

    public static final string ARCHIVE_STATUS_COMPLETED = 'Complete';
    public static final string ARCHIVE_STATUS_PROCESSING = 'Processing';
    public static final string ARCHIVE_STATUS_FAILED = 'Archive Failed';

    public static final string ARCHIVE_MAX_ATTEMPTS = 'Archive_Max_Attempts';
    public static final string ARCHIVE_CRON_EXP = 'Archive_cronExpList';
    public static final string ARCHIVE_NUMBER_OF_DAYS = 'Archive_Number_of_Days';
    
    public static final string NOW_CRON_EXP ='Appt_Now_CronExpTemplate';
    public static final string NOW_LEAD_MINUTES = 'Appt_Now_Lead_Time_Minutes';
    public static final string NOW_NOTIFICATION_TYPES = 'Appt_Now_Notification_Types';
    public static final string NOTIFICATION_INVOICE_STATUS_PENDING = 'Pending';
    public static final string NOTIFICATION_INVOICE_STATUS_SUCCESSFUL = 'Successful';    
    public static final string NOTIFICATION_INVOICE_STATUS_ERROR = 'Error';

    public static final String ADDRESS_DEFAULT_COUNTRY = 'United States';
    //Appt 3.0 - On the fly flag enabled when appointments are created as part of vision implementaion.
    public static Boolean isVisionFeature = false;
    //Appt 3.0 - End point settings to make CAR order histories outbound call
    public static final String INTEGRATION_SETTING_ORDER_HISTORIES_URL = 'Order_Histories_Url';
    //Appt 3.0 - End point settings to make consolidated CAR outbound inventories call
    public static final String INTEGRATION_SETTING_INVENTORIES_URL = 'Inventories_Url';  
    
    //Resource absence lwc related data
    public static final String ABSENCE_TYPE_HOLIDAY = 'Holiday';
    public static final String TIME_AM = 'AM';
    public static final String TIME_PM = 'PM';
}