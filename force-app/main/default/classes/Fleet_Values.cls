public class Fleet_Values
{
    public static final String FLEET_ASSIGNMENT_GROUP_1_50 = '1-50';
    public static final String FLEET_ASSIGNMENT_GROUP_50PLUS = '50+';
    public static final String FLEET_ASSIGNMENT_GROUP_100PLUS = '100+';

    public final static String FLEET_APPLICATION_TYPE_CREDIT = 'Credit';
    public final static String FLEET_APPLICATION_TYPE_CASH = 'Non-Credit';
    public final static String FLEET_APP_FORMAT_ONLINE = 'Online';
    public final static String FLEET_APP_FORMAT_PDF = 'PDF Forms';
    public final static String FLEET_APP_STATUS_APPROVED = 'Approved';
    public final static String FLEET_APP_STATUS_DECLINED = 'Declined';
    public final static String FLEET_APP_ATTACHMENT_STATUS_REVIEWED = 'Reviewed';

    public final static String FLEET_IMPORT_TYPE_DRIVERS = 'Fleet Drivers';
    public final static String FLEET_IMPORT_TYPE_VEHICLES = 'Fleet Vehicles';
    public final static String FLEET_IMPORT_TYPE_DRIVERS_OBJECT = 'Fleet_Driver_Import__c';
    public final static String FLEET_IMPORT_TYPE_VEHICLES_OBJECT = 'Fleet_Vehicle_Import__c';

    public static final String ACCOUNT_STATUS_CUSTOMER = 'Customer';  
    
    public static final String LINE_BREAK = '\r\n';
    public static final Integer MAX_CHARS_PER_LINE = 120;

    public static final String ECC_YES = '01';
    public static final String ECC_NO = '02';

    public static final String MESSAGE_STATUS_SUCCESS = 'success';
    
    public static final String ERROR_RETRY_CRONEXP_LIST = 'Error_Retry_cronExp_List';

    public static final String ERROR_RETRY_MAX_ATTEMPTS = 'Error_Retry_Max_Attempts';
    public static final String ERROR_RETRY_MAX_AGE_MIN = 'Error_Retry_Max_Age_Min';
    public static final String ERROR_RETRY_TYPE_LIST = 'Error_Retry_Type_List';
    public static final String ERROR_RETRY_REC_LIMIT = 'Error_Retry_Rec_Limit';

    public static final String BATCH_SCHEDULE_CRONEXP_LIST = 'Batch_Schedule_cronExp_List';

    public static final String PURGE_REC_LIMIT_QUERY = 'Purge_Rec_Limit_Query';
    public static final String PURGE_DAYS_ALL = 'Purge_Days_All';
    public static final String PURGE_DAYS_COMPLETE = 'Purge_Days_Complete';

    public static final String QUEUED_REC_LIMIT = 'Queued_Rec_Limit';

    public static final String SETTING_SUPPRESS_OUTBOUND_USER_LIST = 'Suppress_Outbound_User_List';
    
    public static final String SETTING_B2B_CUSTOMER_GET_URL = 'B2B_Customer_Get_Url';
    public static final String SETTING_B2B_CUSTOMER_PUT_URL = 'B2B_Customer_Put_Url';

    public static final String SETTING_INVOICE_SUMMARY_URL = 'Invoice_Summary_Url';
    public static final String SETTING_INVOICE_DETAILS_URL = 'Invoice_Details_Url';
    public static final String SETTING_DT_SOURCE_SYSTEM = 'dtSourceSystem';
    public static final String SETTING_DT_SOURCE_SUBSYSTEM = 'dtSourceSubsystem';
    public static final String SETTING_DT_REQUEST_IDENTIFIER = 'dtRequestIdentifier';

    public static final String SETTING_ECC_DISABLE_ALL_OUTGOING = 'ECC_Disable_All_Outgoing';
    public static final String SETTING_ECC_MASK_CUSTOMER_EMAILS = 'ECC_Mask_Customer_Emails';
    public static final String SETTING_ECC_MASK_SUFFIX = 'ECC_Mask_Suffix';

    public static final String SETTING_INT_MESSAGE_MAX_PROCESS_COUNT = 'Int_Message_Max_Process_Count';

    public static final String FLEET_ONLINE_APP_URL_CREDIT = 'account-application-a';
    public static final String FLEET_ONLINE_APP_URL_NONCREDIT= 'account-application-b';
    public static final String FLEET_ONLINE_APP_URL_GUID_PARAM= 'c__a_id';

    //---General Fleet Settings - custom metadata Fleet Settings
    public static final String SETTING_USER_TRIGGER_DISABLE = 'User_Trigger_Disable';
    public static final String SETTING_USER_TRIGGER_FIELD_LIST = 'User_Trigger_Field_List';
    public static final String SETTING_FLEET_COMMUNITY_USER_PROFILE = 'Fleet_Community_User_Profile';
    public static final String SETTING_FLEET_COMMUNITY_USER_PERMISSION_SET = 'Fleet_Community_User_Permission_Set';
    public static final String SETTING_FLEET_COMMUNITY_URL = 'Fleet_Community_URL_Base';
    public final static String SETTING_FLEET_TAX_FORM_ATTACHMENT_STATES = 'Fleet_App_Attachment_Tax_Form_States';

    public static final String SETTING_FLEET_DRIVER_CSV_TEMPLATE = 'Fleet_Driver_Import_CSV_Template';
    public static final String SETTING_FLEET_VEHICLE_CSV_TEMPLATE = 'Fleet_Vehicle_Import_CSV_Template';

    public static final String SETTING_FLEET_AUTO_CREATE_COMMUNITY_USERS = 'Fleet_Auto_Create_Community_Users';


    //---Record Types
    public static final String ASSET_RECORD_TYPE_VEHICLE = 'Vehicle';
    public static final String CONTACT_RECORD_TYPE_DRIVER = 'B2B_Driver';
    public static final String CONTACT_RECORD_TYPE_B2B_CONTACT = 'B2B_Contact';
    public static final String APPLICATION_RECORD_TYPE_CREDIT = 'Credit';
    public static final String APPLICATION_RECORD_TYPE_NONCREDIT = 'Non-Credit';
    public static final String APPLICATION_RECORD_PDF_FORMS = 'PDF';

    public static final String COMMUNITY_ROLE_MANAGER;
    public static final String COMMUNITY_ROLE_USER;
    

}