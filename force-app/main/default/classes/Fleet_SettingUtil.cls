public class Fleet_SettingUtil
{
    public static String lprefix = 'FLEET_SET_UTIL:';

    //---Store as private for cache
    private static List<Fleet_Settings__mdt> fleetSettingList;

    //---Check the cache and query if neeeded
    public static List<Fleet_Settings__mdt> getFleetSettings()
    {
        if (fleetSettingList == null || fleetSettingList.size() == 0)
        {
            fleetSettingList = [SELECT DeveloperName, Value__c FROM Fleet_Settings__mdt];
        }

        return fleetSettingList;
    }

    //---Get a single System Setting, using/reloading the cache if needed
    public static String getSettingValue(String developerName)
    {
        String returnVal = '';

        List<Fleet_Settings__mdt> settingList = getFleetSettings();

        for (Fleet_Settings__mdt sRow : settingList)
        {
            if (sRow.DeveloperName == developerName)
            {
                returnVal = sRow.Value__c;
                break;
            }
        }

        return returnVal;
    }

    //---Get the Integer Value - If empty or invalid, the response will be zero
//--- commenting out since not being called 

    // public static Integer getSettingIntValue(String developerName)
    // {
    //     Integer returnVal = 0;
    //     String currValue = getSettingValue(developerName);

    //     if (currValue == null || currValue == '')
    //     {
    //         System.debug( lprefix + 'Error converting settings ' + developerName + ' to Integer, no setting value found.');   
    //         return returnVal;
    //     } 

    //     try 
    //     {
    //         returnVal = Integer.valueOf(currValue);
    //     } 
    //     catch (Exception ex) 
    //     {
    //         String errorMessage = ex.getMessage();
    //         System.debug( lprefix + 'Error converting settings ' + developerName + ' value: ' + currValue + ' to Integer');   
    //     }

    //     return returnVal;
    // }

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