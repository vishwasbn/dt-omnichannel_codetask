/*========================================================================================================
* @author: Ayna
* @date: 07th Aug '23
* @description: Helper class for Absence creation Lighnting component functionality

Modification Log:
------------------------------------------------------------------------------------
Developer     Jira Number   Date                Description
------------------------------------------------------------------------------------
Ayna           SO-385       07th Aug '23        Created to accommodate all the controller method. 
========================================================================================================== */

public with sharing class TestResourceAbsenceController {

public static Logger logInstance = Logger.getInstance();

// This method will get list of stores on LWC component load and show there as well as used for search stores using search bar in LWC component.
 @AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAllStores(String searchKey){
        List<ServiceTerritory> serviceList = new List<ServiceTerritory>();
        if(String.isBlank(searchKey)){
            serviceList = [SELECT Id,Name,Site_Account__r.Store_ID__c,OperatingHours.Name , OperatingHours.TimeZone	 FROM ServiceTerritory];
        }
        else{
            searchKey = '%' + searchKey + '%';
            serviceList =  [SELECT Id,Name,Site_Account__r.Store_ID__c,OperatingHours.Name , OperatingHours.TimeZone FROM ServiceTerritory where name like :searchKey];
        }
        return serviceList;
    }
    

    // This method will create the resource absence records and will be called from AppresourceAbsence LWC component.
    @AuraEnabled
    public static void createAbsenceRecords(String requestData){
        
        try{
            List<RequestData> lstData = (List<RequestData>) JSON.deserialize(requestData,List<RequestData>.class);
            Set<String> serviceResourceNames = New Set<String>();
            Map<String,RequestData> storeIdMap = new Map<String,RequestData>();
            List<ServiceResource> lstSR = new List<ServiceResource>();
            List<ResourceAbsence> insertResourceAbsenceList = new List<ResourceAbsence>();
            for(RequestData obj : lstData){
                serviceResourceNames.add(obj.StoreId);
                storeIdMap.put(obj.id,obj);
            }
            for(ServiceTerritoryMember memberObj : [SELECT Id, ServiceTerritoryId,ServiceTerritory.Name, ServiceResourceId FROM ServiceTerritoryMember where ServiceTerritory.Name in : serviceResourceNames AND ServiceResource.IsActive=true]){
                ResourceAbsence resourceAbsenceObj = new ResourceAbsence();
                resourceAbsenceObj.Type = Appt_ConstantValues.ABSENCE_TYPE_HOLIDAY;
                resourceAbsenceObj.Start = getDateTimeValue(storeIdMap.get(memberObj.ServiceTerritoryId).StartTime,storeIdMap.get(memberObj.ServiceTerritoryId).StoreDate);
                resourceAbsenceObj.End = getDateTimeValue(storeIdMap.get(memberObj.ServiceTerritoryId).EndTime,storeIdMap.get(memberObj.ServiceTerritoryId).StoreDate);
                resourceAbsenceObj.ResourceId = memberObj.ServiceResourceId;
                insertResourceAbsenceList.add(resourceAbsenceObj);
            }
            insert insertResourceAbsenceList; 
        }catch(Exception e){
            logInstance.log('CreateAbsenceRecords', Appt_ResourceAbsenceController.class.getName(), e.getmessage());
        }
    }

   public Class RequestData{
     public String ServiceTeritoryId;
     public String Name;
     public string id;
      public String StoreId;
      public String StartTime;
      public String EndTime; 
      public String StoreDate;           
    }

   public Class ProcessedData{
      public  String Name;
      public  String Result;

    }
    public static DateTime getDateTimeValue(String timeValue,String DateValue){
        Integer timeonly = Integer.valueOf(timeValue.substring(0,2));
        system.debug(timeonly);
        String ampm = '';
        ampm = timeOnly >= 12 ? Appt_ConstantValues.TIME_PM : Appt_ConstantValues.TIME_AM;
        Integer hours = 0;
        hours = timeOnly > 12 ? timeOnly-12 : timeOnly;
        System.debug(hours + ':'+timeValue.substring(3,5)+ ' ' +ampm);
        System.debug('date : '+DateTime.parse(DateValue.Substring(5,7)+'/'+DateValue.Substring(8,10)+'/'+DateValue.Substring(0,4)+', '+hours+':'+timeValue.substring(3,5)+ ' ' +ampm));
        return DateTime.parse(DateValue.Substring(5,7)+'/'+DateValue.Substring(8,10)+'/'+DateValue.Substring(0,4)+', '+hours+':'+timeValue.substring(3,5)+ ' ' +ampm);
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getOperatingHourOptions() {
        List<Option> options = new List<Option>();
        
        for (OperatingHours oh : [select id, Name, TimeZone from OperatingHours]) {
            options.add(new Option(oh.Id, oh.Name));
        }
        
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Option> getSiteRegions(String operatingHourId) {
        List<Option> options = new List<Option>();
        
        for (AggregateResult ar : [select Site_Account__r.Store_Region__c  from ServiceTerritory where Site_Account__r.RecordType.Name='Site' and OperatingHours.id = :operatingHourId group by Site_Account__r.Store_Region__c]) {
            if(ar.get('Store_Region__c')!=null){
                options.add(new Option(ar.get('Store_Region__c').toString(), ar.get('Store_Region__c').toString()));
            }
            
        }
        
        return options;
    }
    
    public class Option {
        @AuraEnabled
        public String value { get; set; }
        
        @AuraEnabled
        public String label { get; set; }
        
        public Option(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserAccountTimezone() {
        String userTimeZone = '';
        
        // Fetch the current user's account
        User currentUser = [SELECT AccountId, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        if (currentUser != null && currentUser.TimezoneSidKey != null) {
                userTimeZone = currentUser.TimezoneSidKey;
            }
        return userTimeZone;
    }
}