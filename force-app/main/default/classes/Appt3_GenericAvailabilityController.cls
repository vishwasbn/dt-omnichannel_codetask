/******************************************************************************************************
* Project : Appointment 3.0
*******************************************************************************************************
* Business Owner : Discount Tire
* Purpose        : Controller Class that shows Availability for Active Stores.
* Business Logic : Query the Appointment Time Slots,parse database fields into UI representable format
*
*******************************************************************************************************
* Test Class: 
* Dependencies (Other) : Appt3_GenericAvailabilityControllerTest
*
*******************************************************************************************************
* Version   Date          Updated By                       Test          Target        Comments
*                                                          Coverage      Release
*
* 1.0      12/06/2022     sindhur.borusu@discounttire.com    96%         FY23-July    
*****************************************************************************************/
public without sharing class Appt3_GenericAvailabilityController {
    
    @AuraEnabled
    public static String getApptSlots(String siteId, Date startDate){
        System.debug('Appt_GenericAvailabilityController::getApptSlots ' + ' siteId: ' + siteId + ' date: ' + startDate);
        try {
            if(!isStoreActive(siteId)){
                return 'INACTIVESTORE';
            }
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
            
            List<Appt_ScheduleModel> schMdlSlots = new List<Appt_ScheduleModel>();
            for(Appt_Time_Slot__c appt: appts){
                // Appt 3.0 - Skip the unavailable time slots.
                if ((appt.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_FRONT && appt.IsFrontUnavailable__c) || 
                    (appt.Type__c == Appt_ConstantValues.APPT_TIME_SLOT_TYPE_BACK && appt.isBackUnavailable__c)) {
                        continue;
                    }
                // convert to Appt_ScheduleModel to format the dates and calculate values. 
                schMdlSlots.add(new Appt_ScheduleModel(appt, tz));
            }
            System.debug('schMdlSlots: ' + schMdlSlots.size()); 
            System.debug('Appt3_GenericAvailabilityController::getApptSlots END ');
            return JSON.serialize(schMdlSlots);
            
        } catch (Exception e) {
            Appt3_ApptsPageContainerController.logExceptions(e, Appt3_GenericAvailabilityController.class.getName(),'Appointments 3.0');
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    //Method to validate if store is Active
    public static boolean isStoreActive(string siteId){
        List<ServiceTerritory> sTeritoryList = new List<ServiceTerritory>();
        sTeritoryList = [SELECT id, IsActive FROM ServiceTerritory WHERE IsActive=true AND Site_Account__r.SAP_STORE_ID__c=:siteId];
        if(sTeritoryList.size()>0){
            return true;
        }
        return false;
    }
    
    //Method to return AppSlots
    public class ApptSlotsReturnModel {
        
        public Integer apptSlotsNumberDays {get; set;}
        public String scheduleModel {get; set;}
        
        public ApptSlotsReturnModel(Integer apptSlotsNumberDays, String scheduleModel){
            this.apptSlotsNumberDays = apptSlotsNumberDays;
            this.scheduleModel = scheduleModel;
        }
    }
}