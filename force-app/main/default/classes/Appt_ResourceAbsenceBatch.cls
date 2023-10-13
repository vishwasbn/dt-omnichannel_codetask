/*Add Comments*/
public class Appt_ResourceAbsenceBatch implements Database.Batchable<sObject>, Database.Stateful{
    //This map is used while sending email to admin to notify the count of number of resource absence holidays created per store
    public map<string, integer> storeAbsenceMap;
    //Contains the list of custom setting records 
    public List<StoreHolidays__c> storeHolidays;
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Querying StoreHolidays__c from custom setting which are active and holiday start date greater than or equal to today
        storeHolidays = [SELECT id, Active__c, End__c, Name, Start__c  FROM StoreHolidays__c WHERE Active__c = true AND Start__c >= TODAY];
        //storeHolidays = [SELECT id, Active__c, End__c, Holiday_Name__c, Start__c , Is_Processed__c FROM StoreHolidays__c WHERE Active__c = true AND createdDate = TODAY];
        
        //checking if there is atelast a single record in the custom setting so batch can start processing
        if(storeHolidays.size()>0){
            //Getting records from ServiceResource(one store will have two serviceresource records one is front and other is back) along with existing resource absences(if any) and ServiceTerritories(for email process)
            string qry = 'SELECT id, Name, CreatedDate, (SELECT id, ServiceTerritoryId, ServiceTerritory.Name, ServiceTerritory.OperatingHours.TimeZone  FROM ServiceTerritories),(SELECT id, ResourceId, Start, End, Type FROM ResourceAbsences)  FROM ServiceResource WHERE IsActive = true';
            return Database.getQueryLocator(qry);    
        }
        //If there are no custom setting records meeting our criteria then batch should not run
        
        return Database.getQueryLocator('SELECT id FROM ServiceResource LIMIT 0');        
    }
    public void execute(Database.BatchableContext bc, List<ServiceResource> serviceResourceList){
        //the instance of the storeAbsenceMap map should be created only for the first chunk of the batch
        if(storeAbsenceMap == null || storeAbsenceMap.size()==0 || storeAbsenceMap.keySet().size()==0){
            storeAbsenceMap = new map<string, integer>();
        }
        //creating a map to hold holiday unique key and hoiday record for further comparison
        map<string, StoreHolidays__c> holidayKeyHolidayRecMap = new map<string, StoreHolidays__c>();
        for(StoreHolidays__c storeHoliday : storeHolidays){
            //farming holiday unique key in format startdatetime - enddatetime
            string storeHolidayUniqueKey = frameUniqueHoliday(storeHoliday);
            holidayKeyHolidayRecMap.put(storeHolidayUniqueKey,storeHoliday);
        }
        //final absence list to insert records
        List<ResourceAbsence> absenceListToInsert = new List<ResourceAbsence>();
        
        //iterating the service resource records from the chunk to create absence records
        for(ServiceResource sr: serviceResourceList){
            //checking if there are any existing resource absence records for each service resource record.
            //if there are no service absence records then we can cosider it as freshly created service resource record.
            //for freshly created service resource record we are creating all the Absence records from the storeHolidays list
            if(sr.ResourceAbsences != null && sr.ResourceAbsences.size()>0){
                //creating a set to strore the existing resource absence records with the unique key framework to compare with holidayKeyHolidayRecMap
                String storeTimeZone;
                if(sr.ServiceTerritories.size() > 0) {
                    storeTimeZone = sr.ServiceTerritories[0].ServiceTerritory.OperatingHours.TimeZone;
                }
                set<string> absenceKeySet = new set<string>();
                for(ResourceAbsence absence : sr.ResourceAbsences){
                    if(storeTimeZone != null){
                        absenceKeySet.add(convertToCurrentUserTime(absence.Start, storeTimeZone)+'-'+convertToCurrentUserTime(absence.End, storeTimeZone));
                    }                    
                    else{
                        absenceKeySet.add(absence.Start+'-'+absence.End);
                    }
                    
                }
                //iterating the holidayKeyHolidayRecMap for creating Resource Absence records
                for(string fKey : holidayKeyHolidayRecMap.keySet()){
                    //if the holiday is already created then the record will be skipped else will enter into if loop
                    if(!absenceKeySet.contains(fKey)){
                        //here we are assigning values to the newly inserting resourceabsencerecord using reusable method assignResourceAbsence
                        ResourceAbsence absenceInsert = assignResourceAbsence(holidayKeyHolidayRecMap.get(fKey), sr);
                        // storing the record in absenceListToInsert to insert at the last
                        absenceListToInsert.add(absenceInsert);
                        //below logic is to collect the store name and how many holidays have been created per holiday
                        if(storeAbsenceMap.containsKey(sr.ServiceTerritories[0].ServiceTerritory.Name)){
                            integer count = storeAbsenceMap.get(sr.ServiceTerritories[0].ServiceTerritory.Name)+1;
                            storeAbsenceMap.put(sr.ServiceTerritories[0].ServiceTerritory.Name, count);
                        }else{
                            storeAbsenceMap.put(sr.ServiceTerritories[0].ServiceTerritory.Name,1);
                        }
                    }   
                }
            }else{
                //here we have the logic for freshly created store records
                absenceListToInsert.addAll(assignResourceAbsences(storeHolidays, sr, storeAbsenceMap));
            }
        }
        //here finally we are checking the size of the absenceListToInsert and doing insert
        if(absenceListToInsert.size()>0){
            insert absenceListToInsert;
        }
    }
    public void finish(Database.BatchableContext bc){
        //using database .stateful we are maintaining the state of storeAbsenceMap so that we can send email finally in the finish method
        if(storeAbsenceMap != null && storeAbsenceMap.size()>0){
           sendEmailToAdmin(storeAbsenceMap);   
        }
    }
    public static List<ResourceAbsence> assignResourceAbsences(List<StoreHolidays__c> storeHolidays, ServiceResource resource, map<string, integer> strAbsenceMap){
        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
        for(StoreHolidays__c storeHoliday : storeHolidays){
            resourceAbsenceList.add(assignResourceAbsence(storeHoliday, resource));
            if(strAbsenceMap.containsKey(resource.ServiceTerritories[0].ServiceTerritory.Name)){
                integer count = strAbsenceMap.get(resource.ServiceTerritories[0].ServiceTerritory.Name)+1;
                strAbsenceMap.put(resource.ServiceTerritories[0].ServiceTerritory.Name, count);
            }else{
                strAbsenceMap.put(resource.ServiceTerritories[0].ServiceTerritory.Name,1);
            }
        }
        return resourceAbsenceList;
    }
    public static ResourceAbsence assignResourceAbsence(StoreHolidays__c storeHoliday, ServiceResource resource){
        ResourceAbsence rAbsence;
        if(resource.ServiceTerritories.size() > 0) {
       string storeTimezoneName = resource.ServiceTerritories[0].ServiceTerritory.OperatingHours.TimeZone;    
             rAbsence = new ResourceAbsence(
                ResourceId = resource.id,
                start = convertToStoreTime(storeHoliday.Start__c, storeTimezoneName),
                end =  convertToStoreTime(storeHoliday.End__c, storeTimezoneName),
                Type='Holiday',
                RecordtypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability').getRecordTypeId()
            );
        } else {
            rAbsence = new ResourceAbsence(
                ResourceId = resource.id,
                start = storeHoliday.Start__c,
                end =  storeHoliday.End__c,
                Type='Holiday',
                RecordtypeId = Schema.SObjectType.ResourceAbsence.getRecordTypeInfosByDeveloperName().get('Non_Availability').getRecordTypeId()
            );
        }
  return rAbsence;
    }
    public static string frameUniqueHoliday(StoreHolidays__c storeHoliday){
        string fKey = '';
        fKey = storeHoliday.Start__c+'-'+storeHoliday.End__c;
        return fKey;
    }
    public static void sendEmailToAdmin(map<string, integer> strAbsenceMap){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses( new String[] { System.Label.ResourceAbsenceBatchEmailAddress  } );
        mail.setSubject( System.Label.ResourceAbsenceBatchSubject );
        mail.setHtmlBody( System.Label.ResourceAbsenceBatchBody );
        String contentCSV = '';
        for (string strName : strAbsenceMap.keySet()) {
            contentCSV += strName + ',' + strAbsenceMap.get(strName) + '\n';
        }
        String content = 'Store Name, Number Of Records Created\n' + contentCSV;
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName( 'ResourceAbsenceBatch.csv' );
        attachment.setBody( Blob.valueOf( content ) );
        mail.setFileAttachments( new Messaging.EmailFileAttachment[]{ attachment } );
        Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
    }
    public static DateTime convertToStoreTime(DateTime dt,string tzName)  
    {
        TimeZone tzCurrentUser = UserInfo.getTimeZone();
        //Get the timStore which is the timezone record of the store ex: For CST - GMT...America/El_Salvador..
        TimeZone tzStore = TimeZone.getTimeZone(tzName);
        //format will change the UTC time to running user's time
        string dateInCurrentUserTimeZone = dt.format('yyyy-MM-dd HH:mm:ss');
        //system.debug('Date In Current User '+tzCurrentUser.getDisplayName()+' TimeZone ' + dateInCurrentUserTimeZone);
        string dateInStoreTimeZone = dt.format('yyyy-MM-dd HH:mm:ss', tzName);
        //system.debug('Date In Store '+tzStore.getDisplayName()+' TimeZone ' + dateInStoreTimeZone);
        Integer diff = Integer.valueOf((DateTime.valueOfGmt(dateInCurrentUserTimeZone).getTime() - DateTime.valueOfGmt(dateInStoreTimeZone).getTime())/(1000*60*60));
        //system.debug(diff);
        DateTime adjustedDateTime = dt.addHours(diff);
        //system.debug(adjustedDateTime.format('yyyy-MM-dd HH:mm:ss'));
        //Note: The adjustedDateTime is still in UTC
        return adjustedDateTime;
    }  
    
    public static DateTime convertToCurrentUserTime(DateTime dt,string tzName)  
    {
        //Get the timStore which is the timezone record of the store ex: For CST - GMT...America/El_Salvador..
        TimeZone tzStore = TimeZone.getTimeZone(tzName);
        //format will change the UTC time to running user's time
        string dateInCurrentUserTimeZone = dt.format('yyyy-MM-dd HH:mm:ss');
        string dateInStoreTimeZone = dt.format('yyyy-MM-dd HH:mm:ss', tzName);
        Integer diff = Integer.valueOf((DateTime.valueOfGmt(dateInStoreTimeZone).getTime() - DateTime.valueOfGmt(dateInCurrentUserTimeZone).getTime())/(1000*60));
        DateTime adjustedDateTime = dt.addMinutes(diff);
        //Note: The adjustedDateTime is still in UTC
        return adjustedDateTime;
    }
}