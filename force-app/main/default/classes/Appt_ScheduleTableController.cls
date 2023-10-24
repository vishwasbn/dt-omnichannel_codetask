public with sharing class Appt_ScheduleTableController {
     // inner store hours object
    public class StoreHours {
        public Integer startTimeHour;
        public Integer startTimeMinute;  
        public Integer endTimeHour;
        public Integer endTimeMinute;
        public String dayOfWeek;           
    }

    
    @AuraEnabled
    public static String getAppointments(String siteId, Date startDate, Date endDate, string type){
        Date parsedStartDate = Date.valueOf(startDate);
        List<Appt_Time_Slot__c> appts;
        System.debug('Parsed Date '+parsedStartDate + ' Original '+ startDate);
        //-- Split SOQL into FRONT or BACK to accomidate IsFrontUnavailable__c and isBackUnavailable__c booleans - DTA-400
        if (type == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT) {
            System.debug('Appt_ScheduleTableController, grabbing front appts');
            //--FRONT SLOTS SOQL
            appts = [SELECT Id, Type__c, BSF_Available__c, BSF_Capacity__c, BSR_Available__c, BSR_Capacity__c, BWF_Available__c, BWF_Capacity__c,
            BWR_Available__c, BWR_Capacity__c, FSF_Available__c, FSF_Capacity__c, FSR_Available__c, FSR_Capacity__c, FWF_Available__c, FWF_Capacity__c,
            FWR_Available__c, FWR_Capacity__c, Start_Time__c, End_Time__c, Date__c FROM Appt_Time_Slot__c 
            WHERE IsFrontUnavailable__c = false AND Type__c = :type AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c = :parsedStartDate ORDER BY Start_Time__c];
            //System.debug('Appt_ScheduleTableController, grabbed fr appointments: ' +appts);

        } else {
           // System.debug('Appt_ScheduleTableController, grabbing back appts');
            //--BACK SLOTS SOQL
            appts = [SELECT Id, Type__c, BSF_Available__c, BSF_Capacity__c, BSR_Available__c, BSR_Capacity__c, BWF_Available__c, BWF_Capacity__c,
            BWR_Available__c, BWR_Capacity__c, FSF_Available__c, FSF_Capacity__c, FSR_Available__c, FSR_Capacity__c, FWF_Available__c, FWF_Capacity__c,
            FWR_Available__c, FWR_Capacity__c, Start_Time__c, End_Time__c, Date__c FROM Appt_Time_Slot__c 
            WHERE isBackUnavailable__c = false AND Type__c = :type AND Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND Date__c = :parsedStartDate ORDER BY Start_Time__c];
           System.debug('Appt_ScheduleTableController, grabbing back appts');  
        }
        
        // Fetching the timezone for the site that is being passed in for formatting purposes
        List<ServiceTerritory> st = [SELECT Id, OperatingHoursId, OperatingHours.TimeZone, Site_Account__r.Id FROM ServiceTerritory 
        WHERE Site_Account__r.SAP_STORE_ID__c = :siteId LIMIT 1];
        String tz;
        
        for(Appt_Time_Slot__c appt: appts){
            System.debug('appt slot availability: ' +appt.BSR_Available__c);
        }


        if(st.size() == 0){
            System.debug('No territories found');
        }
        else {
            tz = st[0].OperatingHours.TimeZone;
        }


        List<Appt_ScheduleModel> slots = new List<Appt_ScheduleModel>();
        for(Appt_Time_Slot__c appt: appts){
            slots.add(new Appt_ScheduleModel(appt, tz));
        }

        return JSON.serialize(slots);
    }


    // gets the stores operating hours 
    @AuraEnabled
    public static String getStoreHours(String siteId){
        System.debug('site id in store hours->'+siteId);
        List<StoreHours> storeHours = new List<StoreHours>();
        List<TimeSlot> storeHoursTimeSlots = new List<TimeSlot>();

        ServiceTerritory st = [SELECT Id, OperatingHoursId FROM ServiceTerritory 
        WHERE Site_Account__r.SAP_STORE_ID__c = :siteId LIMIT 1];

        if(st != null && st.OperatingHoursId != null){
            storeHoursTimeSlots = [Select id, StartTime, EndTime, DayOfWeek FROM TimeSlot WHERE OperatingHoursId = :st.OperatingHoursId];
            System.debug('storeHoursTimeSlots:'+storeHoursTimeSlots);
        }

        // convert store hours into an object for the LWC to work with
        if(storeHoursTimeSlots != null){
            for(TimeSlot ts: storeHoursTimeSlots){                
                StoreHours storeHour = new StoreHours();
                storeHour.startTimeHour = ts.StartTime.hour();
                storeHour.startTimeMinute = ts.StartTime.minute();
                storeHour.endTimeHour = ts.EndTime.hour();
                storeHour.endTimeMinute = ts.EndTime.minute();
                storeHour.dayOfWeek = ts.dayOfweek;
                storeHours.add(storeHour);
            }
        }
        system.debug('storeHours->'+storeHours);
        return JSON.serialize(storeHours);

    }
    
    // Appt 3.0 - gets dates that needs to be displayed as functional on the calendar component.
    @AuraEnabled
    public static List<String> getFunctionalDates(String siteId, Date startDate){
        Integer apptTimeSlotsNumberOfDays = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_NUMBER_DAYS_APPT_TIME_SLOTS));
        Date parsedStartDate = Date.valueOf(startDate);
        Date futureEndDate = parsedStartDate.addDays(apptTimeSlotsNumberOfDays);
        Date parsedEndDate = Date.valueOf(futureEndDate);
    
        List<String> datesList = new List<String>();
        for(AggregateResult ar : [SELECT Date__c FROM Appt_Time_Slot__c WHERE IsFrontUnavailable__c = false AND isBackUnavailable__c = false AND 
                                  Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :siteId AND 
                                  (Date__c >= :parsedStartDate AND Date__c <= :parsedEndDate) GROUP BY Date__c ORDER BY Date__c ASC]){
            datesList.add(String.valueOf(ar.get('Date__c')));
        }
        system.debug('datesList->'+datesList);
        return datesList;
    }

   

}