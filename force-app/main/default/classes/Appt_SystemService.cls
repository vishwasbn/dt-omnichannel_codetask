public class Appt_SystemService {

    public static String lprefix = 'Appt_SServ: ';

    //pass-through method to calculate avaialble Appt_Time_Slot for a site
    public static Appt_SiteAvailabilityModel getSiteAvailability(Appt_GetAvailabilityServiceModel availModel){
        System.debug(lprefix+'getSiteAvailability() ENTRY');

        Appt_SiteAvailabilityModel returnModel = Appt_AvailabilityHandler.calculateAvailableTimes(availModel);

        System.debug(lprefix+'getSiteAvailability() EXIT - returnModel:' + returnModel);
        return returnModel;
    }


    //pass-through method to create an appointment
    public static Appt_CreateAppointmentServiceModel createAppointment(Appt_CreateAppointmentServiceModel apptModel){
        System.debug(lprefix+'createAppointment() ENTRY - apptModel:' + apptModel);

        Appt_CreateAppointmentServiceModel returnModel = Appt_AppointmentHandler.createAppointment(apptModel);

        System.debug(lprefix+'createAppointment() EXIT - returnModel:' + returnModel);
        return returnModel;
    }


    //pass-through method to create an appointment
    public static Appt_UpdateAppointmentServiceModel updateAppointment(Appt_UpdateAppointmentServiceModel apptModel){
        System.debug(lprefix+'updateAppointment() ENTRY - apptModel:' + apptModel);

        Appt_UpdateAppointmentServiceModel returnModel = Appt_AppointmentUpdateHandler.updateAppointment(apptModel);

        System.debug(lprefix+'updateAppointment() EXIT - returnModel:' + returnModel);
        return returnModel;
    }


    //pass-through method to checkAvailability, to check if an appointment slot is available
    public static Boolean checkAvailability(Appt_GetAvailabilityServiceModel availModel){
        System.debug(lprefix+'checkAvailability() ENTRY - availModel:' + availModel);

        if (availModel != null) availModel.availabilityOnly = true;
        
        Boolean isAvailable = Appt_AvailabilityHandler.checkAvailability(availModel);

        System.debug(lprefix+'checkAvailability() EXIT - isAvailable:' + isAvailable);
        return isAvailable;
    }


    //get all appt time slots for a site
    public static List<Appt_Time_Slot__c> getTimeSlotsBySite(String siteId, Date startdate, Date endDate) {
        System.debug(lprefix+'getTimeSlotsBySite() ENTRY - siteId=' + siteId + ',startdate=' + startdate + ', endDate=' + endDate);
        
        List<Appt_Time_Slot__c> returnSlots = Appt_AvailabilityHandler.getTimeSlotsBySite(siteId, startdate, endDate);

        System.debug(lprefix+'getTimeSlotsBySite() EXIT - returnSlots:' + returnSlots);
        return returnSlots;
    }
}