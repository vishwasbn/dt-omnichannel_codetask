public class Fleet_ApplicationTriggerHandler 
{
    public static String lprefix = 'LOG_ATH:';

    //---Primary Account Trigger Handler for Fleet
    public static void handle(Map<Id, Fleet_Application__c> oldMap, Map<Id, Fleet_Application__c> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Fleet_ApplicationTriggerHandler - START');

        switch on triggerEvent 
        {
            when AFTER_INSERT 
            {
                checkForOldPrimaryNew( newMap);
            }
            when AFTER_UPDATE 
            {
                checkForOldPrimary( oldMap, newMap);
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Fleet_ApplicationTriggerHandler - END');
    }

    //---Check for other Apps that are not primary
    public static void checkForOldPrimaryNew(Map<Id, Fleet_Application__c> newMap)
    {   
        Set<Id> primaryAppIdSet = new Set<Id>();
        Set<Id> parentAccountIdSet = new Set<Id>();

        //---Scan the trigger Apps for primary
        for( Fleet_Application__c newObj : newMap.values())
        {
            if (newObj.Is_Primary_Application__c == true) 
            {
                primaryAppIdSet.add(newObj.Id);
                parentAccountIdSet.add(newObj.Parent_Account__c);
            }
        }

        updateOtherApps( primaryAppIdSet, parentAccountIdSet);
    }

    //---Check for other Apps that are not primary
    public static void checkForOldPrimary(Map<Id, Fleet_Application__c> oldMap, Map<Id, Fleet_Application__c> newMap)
    {   
        Set<Id> primaryAppIdSet = new Set<Id>();
        Set<Id> parentAccountIdSet = new Set<Id>();

        //---Scan the trigger Apps for primary
        for( Fleet_Application__c newObj : newMap.values())
        {
            //---Reference to the Old Object
            Fleet_Application__c oldObj = oldMap.get( newObj.Id);

            if (oldObj.Is_Primary_Application__c != newObj.Is_Primary_Application__c && newObj.Is_Primary_Application__c == true) 
            {
                primaryAppIdSet.add(newObj.Id);
                parentAccountIdSet.add(newObj.Parent_Account__c);
            }
        }

        updateOtherApps( primaryAppIdSet, parentAccountIdSet);
    }

    //---Update the Primary Flag on the Other Apps
    public static void updateOtherApps(  Set<Id> primaryAppIdSet, Set<Id> parentAccountIdSet)
    {
        //---If there are Primary Apps
        if (parentAccountIdSet.size() > 0)
        {
            //---Get all primary Apps related to the same Account
            List<Fleet_Application__c> allAppList = [SELECT Id, Is_Primary_Application__c FROM Fleet_Application__c WHERE Parent_Account__c IN :parentAccountIdSet AND Id NOT IN :primaryAppIdSet];
            System.debug( lprefix + 'Found the following related Apps:' + allAppList);

            if (allAppList != null && allAppList.size() > 0)
            {
                List<Fleet_Application__c> updateAppList = new List<Fleet_Application__c>();

                for (Fleet_Application__c appRow : allAppList)
                {
                    updateAppList.add( new Fleet_Application__c(Id=appRow.Id, Is_Primary_Application__c=FALSE));
                }

                System.debug( lprefix + 'Updating the following Applications, setting Primary to False:' + updateAppList);

                //---Update the Apps
                update updateAppList;
            }
        }
    }
}