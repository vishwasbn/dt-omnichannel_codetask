public class Fleet_AssetTriggerHandler
{
    public static String lprefix = 'LOG_ASSETTH:';

    //---Primary Asset Trigger Handler for Fleet
    public static void handle(Map<Id, Asset> oldMap, Map<Id, Asset> newMap, System.TriggerOperation triggerEvent )
    {
        System.debug( lprefix + 'Fleet Fleet_AssetTriggerHandler Handler - START');

        switch on triggerEvent 
        {
            when AFTER_INSERT 
            {
                updateAfterInsert(oldMap, newMap);
            }
            when BEFORE_UPDATE
            {
                updateBeforeUPdate(oldMap, newMap);
            }
            when else {
                //do nothing 
            }
        }

        System.debug( lprefix + 'Fleet Fleet_AssetTriggerHandler Handler - END');
    }

    //---Update the Name field for Community Created Assets, and check Vehicle Type Field
    public static void updateAfterInsert(Map<Id, Asset> oldMap, Map<Id, Asset> newMap)
    {   
        Id vehicleRT = Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        //---Get Picklist Values
        Schema.DescribeFieldResult fieldResult = Asset.Vehicle_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
     
        List<Asset> updateList = new List<Asset>();

        for( Asset newObj : newMap.values())
        {
            if (newObj.RecordTypeId == vehicleRT)
            {
                Asset updateObj = new Asset(Id=newObj.Id, Name=newObj.Vehicle_Number__c);

                //---Update the Vehicle Type if needed  (Other has value and VType is empty)
                if (newObj.Vehicle_Type_Other__c != null && newObj.Vehicle_Type_Other__c != '' && (newObj.Vehicle_Type__c == null || newObj.Vehicle_Type__c == ''))
                {
                    for( Schema.PicklistEntry pickListVal : ple)
                    {
                        if (pickListVal.getLabel() == newObj.Vehicle_Type_Other__c)
                        {
                            updateObj.Vehicle_Type__c = newObj.Vehicle_Type_Other__c;
                        }
                    }
                }

                updateList.add( updateObj);
            }
        }

        if (updateList.size() > 0) update updateList;
    }

    //---Update Vehicle Type Field
    public static void updateBeforeUPdate(Map<Id, Asset> oldMap, Map<Id, Asset> newMap)
    {   
        Id vehicleRT = Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        //---Get Picklist Values
        Schema.DescribeFieldResult fieldResult = Asset.Vehicle_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Asset newObj : newMap.values())
        {
            if (newObj.RecordTypeId == vehicleRT)
            {
                //---Update the Vehicle Type if needed  (Other has value and VType is empty)
                if (newObj.Vehicle_Type_Other__c != null && newObj.Vehicle_Type_Other__c != '' && (newObj.Vehicle_Type__c == null || newObj.Vehicle_Type__c == ''))
                {
                    for( Schema.PicklistEntry pickListVal : ple)
                    {
                        if (pickListVal.getLabel() == newObj.Vehicle_Type_Other__c)
                        {
                            newObj.Vehicle_Type__c = newObj.Vehicle_Type_Other__c;
                        }
                    }
                }
            }
        }
    }
}