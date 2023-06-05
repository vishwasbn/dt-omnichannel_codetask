public with sharing class Fleet_ApplicationUtil {

   @AuraEnabled(cacheable=true)
   public static String getCreditLimitPicklistValues()
   {
         String strObjectName = 'Fleet_Application__c'; 
       System.debug('Inide get recit');
       List<PickVal> picklist = new List<PickVal>();
        String strPicklistField = 'Credit_Limit_Requested__c';
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            System.debug('Value = ' +objPickList.getValue() +' , Label = ' +objPickList.getLabel());
           PickVal pickValue = new PickVal();
            pickValue.label= objPickList.getLabel();
            pickValue.value=objPickList.getValue();
            picklist.add(pickValue);
        }
       System.debug(JSON.serialize(picklist));
       return JSON.serialize(picklist);
       
   }
       class PickVal
       {
           String label;
           String value;           
       }      
   
}