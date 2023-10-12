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
        List<ServiceTerritory> storeList = new List<ServiceTerritory>();
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
        storeList = Database.query(soqlQuery);
        
        return storeList;
    }
    

    // This method is used to create the resource absence records
    @AuraEnabled
    public static ResponseWrapper createAbsenceRecords(String requestData){
        ResponseWrapper rw = new ResponseWrapper();
        try{
            List<RAToCreateWrapper> resourceAbsenceDataList = (List<RAToCreateWrapper>) JSON.deserialize(requestData,List<RAToCreateWrapper>.class);
            Set<String> serviceTerritoryId = New Set<String>();
            Map<String,RAToCreateWrapper> resourceAbsenceDataMap = new Map<String,RAToCreateWrapper>();
            List<ResourceAbsence> raToInsert = new List<ResourceAbsence>();
            for(RAToCreateWrapper obj : resourceAbsenceDataList){
                serviceTerritoryId.add(obj.id); //holds the Store name 
                resourceAbsenceDataMap.put(obj.id,obj); //map of territorry id and the resource absence data
            }
            for(ServiceTerritoryMember memberObj : [SELECT Id, ServiceTerritoryId,ServiceTerritory.Name, ServiceResourceId FROM ServiceTerritoryMember where ServiceTerritory.Id in : serviceTerritoryId AND ServiceResource.IsActive = true AND ServiceResource.Type__c = 'Back Room']){
                ResourceAbsence ra = new ResourceAbsence();
                ra.Type = Appt_ConstantValues.ABSENCE_TYPE_HOLIDAY;
                ra.Start = getDateTimeValue(resourceAbsenceDataMap.get(memberObj.ServiceTerritoryId).StartTime,resourceAbsenceDataMap.get(memberObj.ServiceTerritoryId).StoreDate);//sets start time in the datetime in logged in user time locale
                ra.End = getDateTimeValue(resourceAbsenceDataMap.get(memberObj.ServiceTerritoryId).EndTime,resourceAbsenceDataMap.get(memberObj.ServiceTerritoryId).StoreDate);//sets end time in the datetime in logged in user time locale
                ra.ResourceId = memberObj.ServiceResourceId;
                raToInsert.add(ra);
            }
            insert raToInsert; // create the resource absence record

            rw.isError = false;
            rw.messsage = JSON.serialize(raToInsert); 
            return rw;

        }catch(Exception e){
            logInstance.log('CreateAbsenceRecords', Appt_ResourceAbsenceController.class.getName(), e.getmessage());
            System.debug('Exception occured during absence creation'+e.getMessage()+' '+e.getStackTraceString());
            rw.isError = true;
            rw.messsage = e.getMessage() + ' - ' + e.getStackTraceString(); 
            return rw;
        }
    }  

    //This method is used to convert the date and time string value to datetime in the loggedin timezone
    public static DateTime getDateTimeValue(String timeString,String dateString){
        Date dateValue = Date.valueOf(dateString);//Returns a Date that contains the value of the specified String
        Integer hour = Integer.valueOf(timeString.substring(0,2));
        Integer minute = Integer.valueOf(timeString.substring(3,5));
        Time timeValue = Time.newInstance(hour,minute, 0, 0); //Constructs a Time from Integer representations of the specified hour, minutes
        DateTime dt = DateTime.newInstance(dateValue, timeValue);//DateTime from the specified date and time in the local time zone 
        return dt;
    }

    // This method is used to retrived the operating hour record as picklist for the lwc component
    @AuraEnabled(cacheable=true)
    public static List<Option> getOperatingHourOptions() {
        List<Option> options = new List<Option>();
        //get the unique Operating Hour record
        // for (AggregateResult ar : [select OperatingHours.Name , OperatingHoursId from ServiceTerritory where IsActive = true  group by OperatingHours.Name, OperatingHoursId  Order by OperatingHours.Name ASC ]) {
        //     options.add(new Option(ar.get('Name').toString(), ar.get('OperatingHoursId').toString()));
        // }
        for (OperatingHours oh : [SELECT Id, Name FROM OperatingHours WHERE Type__c ='Store Hours']) {
            options.add(new Option(oh.Name, oh.Id));
        }
        
        return options;
    }

    //This method used to retrived the Store regions based on the store Operating hour
    @AuraEnabled(cacheable=true)
    public static List<Option> getSiteRegions(String operatingHourId) {
        List<Option> options = new List<Option>();
        //get the unique store region
        for (AggregateResult ar : [select Site_Account__r.Store_Region__c  from ServiceTerritory where IsActive = true and OperatingHours.id = :operatingHourId group by Site_Account__r.Store_Region__c Order by Site_Account__r.Store_Region__c ASC ]) {
            if(ar.get('Store_Region__c')!=null){
                options.add(new Option(ar.get('Store_Region__c').toString(), ar.get('Store_Region__c').toString()));
            }
            
        }
        
        return options;
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

    //wrapper class to hold the resource absence details to be created, data from lwc
    public Class RAToCreateWrapper{
        public String ServiceTeritoryId;
        public String Name;
        public string id;
        public String StoreId;
        public String StartTime;
        public String EndTime; 
        public String StoreDate;           
    }

    //this is the wrapper class to hold the resource absence creation method response
    public class ResponseWrapper{
        @auraEnabled
        public String messsage{get;set;}
        @auraEnabled
        public Boolean isError{get;set;}
    }

    //wrapper class to construct the dropdown value options for lwc
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
}