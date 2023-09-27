/*========================================================================================================
* @author: Ayna
* @date: 07th Aug '23
* @description: Helper class for Absence creation Lighnting component functionality

Modification Log:
------------------------------------------------------------------------------------
Developer     Jira Number   Date                Description
------------------------------------------------------------------------------------
Ayna           SO-385       07th Aug '23        Created to accommodate all the controller method. 
Vishwas        S0-385       25-08-2023          Added methods to list Operating Hours, Store Region and get logged in user timezone.
========================================================================================================== */

public with sharing class Appt_ResourceAbsenceController {

public static Logger logInstance = Logger.getInstance();

// This method will get list of stores on component and filter store based on region and search key
    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAllStores(String operatingHourId , String region, String searchKey){
        List<ServiceTerritory> serviceList = new List<ServiceTerritory>();
        String soqlQuery = 'SELECT Id,Name,Site_Account__r.Store_ID__c,OperatingHours.Name , OperatingHours.TimeZone,Site_Account__r.Store_Region__c FROM ServiceTerritory where IsActive = true';
        if (!String.isEmpty(operatingHourId)) {
            soqlQuery += ' and OperatingHoursId=\'' + operatingHourId + '\'';
        }
        if (!String.isEmpty(searchKey)) {
            soqlQuery += ' and Name LIKE \'%' + searchKey + '%\'';
        }
        if (!String.isEmpty(region)) {
            soqlQuery += ' and Site_Account__r.Store_Region__c LIKE \'%' + region + '%\'';
        }
        soqlQuery += ' Order by Name asc';
        serviceList = Database.query(soqlQuery);
        
        return serviceList;
    }
    

    // This method is used to create the resource absence records
    @AuraEnabled
    public static ResponseWrapper createAbsenceRecords(String requestData){
        ResponseWrapper rw = new ResponseWrapper();
        try{
            List<RequestData> lstData = (List<RequestData>) JSON.deserialize(requestData,List<RequestData>.class);
            Set<String> serviceResourceNames = New Set<String>();
            Map<String,RequestData> storeIdMap = new Map<String,RequestData>();
            List<ServiceResource> lstSR = new List<ServiceResource>();
            List<ResourceAbsence> insertResourceAbsenceList = new List<ResourceAbsence>();
            TimeZone tz = UserInfo.getTimeZone();
            for(RequestData obj : lstData){
                serviceResourceNames.add(obj.StoreId);
                storeIdMap.put(obj.id,obj);
            }
            for(ServiceTerritoryMember memberObj : [SELECT Id, ServiceTerritoryId,ServiceTerritory.Name, ServiceResourceId FROM ServiceTerritoryMember where ServiceTerritory.Name in : serviceResourceNames AND ServiceResource.IsActive = true AND ServiceResource.Type__c = 'Back Room']){
                ResourceAbsence resourceAbsenceObj = new ResourceAbsence();
                resourceAbsenceObj.Type = Appt_ConstantValues.ABSENCE_TYPE_HOLIDAY;
                resourceAbsenceObj.Start = getDateTimeValue(storeIdMap.get(memberObj.ServiceTerritoryId).StartTime,storeIdMap.get(memberObj.ServiceTerritoryId).StoreDate);
                resourceAbsenceObj.End = getDateTimeValue(storeIdMap.get(memberObj.ServiceTerritoryId).EndTime,storeIdMap.get(memberObj.ServiceTerritoryId).StoreDate);
                resourceAbsenceObj.ResourceId = memberObj.ServiceResourceId;
                insertResourceAbsenceList.add(resourceAbsenceObj);
            }
            insert insertResourceAbsenceList;
            rw.isError = false;
            rw.messsage = JSON.serialize(insertResourceAbsenceList); 
            return rw;
        }catch(Exception e){
            logInstance.log('CreateAbsenceRecords', Appt_ResourceAbsenceController.class.getName(), e.getmessage());
            System.debug('Exception occured during absence creation'+e.getMessage()+' '+e.getStackTraceString());
            rw.isError = true;
            rw.messsage = e.getMessage() + ' - ' + e.getStackTraceString(); 
            return rw;
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

    //This method is used to convert the date and time string value to datetime in the loggedin timezone
    public static DateTime getDateTimeValue(String timeString,String dateString){
        
        Date dateValue = Date.valueOf(dateString);
        Integer hour = Integer.valueOf(timeString.substring(0,2));
        Integer minute = Integer.valueOf(timeString.substring(3,5));
        Time timeValue = Time.newInstance(hour,minute, 0, 0);
        DateTime dt = DateTime.newInstance(dateValue, timeValue);
        return dt;

    }

    // This method is used to retrived the operating hour record as picklist for the lwc component
    @AuraEnabled(cacheable=true)
    public static List<Option> getOperatingHourOptions() {
        List<Option> options = new List<Option>();
        
        for (AggregateResult ar : [select OperatingHours.Name , OperatingHoursId from ServiceTerritory where IsActive = true  group by OperatingHours.Name, OperatingHoursId  Order by OperatingHours.Name ASC ]) {
            options.add(new Option(ar.get('Name').toString(), ar.get('OperatingHoursId').toString()));
        }
        
        return options;
    }

    //This method used to retrived the Store regions based on the store Operating hour
    @AuraEnabled(cacheable=true)
    public static List<Option> getSiteRegions(String operatingHourId) {
        List<Option> options = new List<Option>();
        
        for (AggregateResult ar : [select Site_Account__r.Store_Region__c  from ServiceTerritory where IsActive = true and OperatingHours.id = :operatingHourId group by Site_Account__r.Store_Region__c Order by Site_Account__r.Store_Region__c ASC ]) {
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
        
        public Option(String label, String value) {
            this.value = value;
            this.label = label;
        }
    }

    //This method is used to retrive logged in user timezone.
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

    public class ResponseWrapper{
        @auraEnabled
        public String messsage{get;set;}
        @auraEnabled
        public Boolean isError{get;set;}
    }
}