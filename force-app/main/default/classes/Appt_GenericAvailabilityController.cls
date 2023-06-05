public with sharing class Appt_GenericAvailabilityController {

    @AuraEnabled
    public static String getApptSlots(String siteId, Date startDate){
        if(!isStoreActive(siteId)){
            return 'INACTIVESTORE';
        }
        System.debug('Appt_GenericAvailabilityController::getApptSlots ' + ' siteId: ' + siteId + ' date: ' + startDate);
        Date parsedStartDate = Date.valueOf(startDate);
        List<Appt_Time_Slot__c> appts = Appt_SystemService.getTimeSlotsBySite(siteId, parsedStartDate, parsedStartDate); // Date comparison
        System.debug('Appt Time Slots: ' + appts.size());
        
        // Fetching the timezone for the site that is being passed in for formatting purposes
        List<ServiceTerritory> st = [SELECT Id, OperatingHoursId, OperatingHours.TimeZone, Site_Account__r.Id FROM ServiceTerritory WHERE Site_Account__r.SAP_STORE_ID__c = :siteId];
        String tz;
        if(st.size() == 0){
            System.debug('No territories found');
        }
        else {
            tz = st[0].OperatingHours.TimeZone;
            System.debug('Timezone: ' + tz);
        }

        List<Appt_ScheduleModel> SchMdl_Slots = new List<Appt_ScheduleModel>();
        for(Appt_Time_Slot__c appt: appts){
            // convert to Appt_ScheduleModel to format the dates and calculate values
            SchMdl_Slots.add(new Appt_ScheduleModel(appt, tz));
            // System.debug('Time Slot: ' + slots[slots.size() - 1]);
        }
        System.debug('SchMdl_Slots: ' + SchMdl_Slots.size());
        for(Appt_ScheduleModel sch :SchMdl_Slots){
            system.debug('slotId=>'+sch.slotId);
            system.debug('this.fsrCapacity=>'+sch.fsrCapacity);
        }
            
        System.debug('Appt_GenericAvailabilityController::getApptSlots END ');
        return JSON.serialize(SchMdl_Slots);
    }
    public static boolean isStoreActive(string siteId){
        List<ServiceTerritory> sTeritoryList = new List<ServiceTerritory>();
        sTeritoryList = [SELECT id, IsActive FROM ServiceTerritory WHERE IsActive=true AND Site_Account__r.SAP_STORE_ID__c=:siteId];
        if(sTeritoryList.size()>0){
            return true;
        }
        return false;
    }

}