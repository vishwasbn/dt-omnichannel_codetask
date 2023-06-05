public class Appt_SettingUtil {

    public static String lprefix = 'APPT_SET_UTIL:';

    //---Store as private for cache
    private static List<Appt_Appointment_Setting__mdt> apptSettingList;
    private static List<Appt_Notification_SMS_Message__mdt> notificationMessages;

    //---Check the cache and query if neeeded
    public static List<Appt_Notification_SMS_Message__mdt> getNotificationMessagesSettings()
    {
        if (notificationMessages == null || notificationMessages.size() == 0)
        {
            notificationMessages = [SELECT DeveloperName, Message__c, Redirect_URL__c  FROM Appt_Notification_SMS_Message__mdt];
        }

        return notificationMessages;
    }

    //---Get a single Appt_Notification_SMS_Message__mdt System Setting, using/reloading the cache if needed
    public static Appt_Notification_SMS_Message__mdt getMessageSettingValue(String developerName)
    {
        Appt_Notification_SMS_Message__mdt returnVal = new Appt_Notification_SMS_Message__mdt();

        List<Appt_Notification_SMS_Message__mdt> settingList = getNotificationMessagesSettings();

        for (Appt_Notification_SMS_Message__mdt sRow : settingList)
        {
            if (sRow.DeveloperName == developerName)
            {
                returnVal = sRow;
                break;
            }
        }

        return returnVal;
    }


    //---Check the cache and query if neeeded
    public static List<Appt_Appointment_Setting__mdt> getApptSettings()
    {
        if (apptSettingList == null || apptSettingList.size() == 0)
        {
            apptSettingList = [SELECT DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt];
        }

        return apptSettingList;
    }

    //---Get a single System Setting, using/reloading the cache if needed
    public static String getSettingValue(String developerName)
    {
        String returnVal = '';

        List<Appt_Appointment_Setting__mdt> settingList = getApptSettings();

        for (Appt_Appointment_Setting__mdt sRow : settingList)
        {
            if (sRow.DeveloperName == developerName)
            {
                returnVal = sRow.Value__c;
                break;
            }
        }

        return returnVal;
    }

    //---Get a single System Setting, using/reloading the cache if needed
    public static String getSettingValue(String developerName, List<Appt_Appointment_Setting__mdt> settingList)
    {
        String returnVal = '';

        for (Appt_Appointment_Setting__mdt sRow : settingList)
        {
            if (sRow.DeveloperName == developerName)
            {
                returnVal = sRow.Value__c;
                break;
            }
        }

        return returnVal;
    }


    //---Get the Boolean Value - If empty or invalid, the response will be false
    public static Boolean getSettingBooleanValue(String developerName)
    {
        Boolean returnVal = false;
        String currValue = getSettingValue(developerName);

        if (currValue != null && currValue != '' && (currValue.toUpperCase().contains('YES') || currValue.toUpperCase().contains('TRUE')))
        {
            returnVal = true;
        }

        return returnVal;
    }
}