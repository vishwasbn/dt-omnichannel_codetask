@isTest
public with sharing class Appt_GenericAvailabilityControllerTest {
    public Appt_GenericAvailabilityControllerTest() {

    }

    @testSetup
    static void setupData() {
        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }

    @isTest
    static void getApptSlotsTest(){
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();

        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');

        String storeId = appts[0].ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;

        List<Appt_Time_Slot__c> timeSlots = [SELECT Id, Service_Territory__r.Id FROM Appt_Time_Slot__c WHERE Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :storeId AND  Date__c=:currentDate];
        System.assertEquals(true, timeSlots.size() != 0, 'There are no time slots present');

        List<Appt_ScheduleModel> models = new List<Appt_ScheduleModel>();

        String timeSlotsJson = Appt_GenericAvailabilityController.getApptSlots(storeId, currentDate);

        // FR Models and BR Models that are retrieved from the ScheduleTableController
        models = (List<Appt_ScheduleModel>) JSON.deserialize(timeSlotsJson, List<Appt_ScheduleModel>.class);

        System.debug('timeSlots size = ' +timeSlots.size() +'\nfrModels size = ' +models.size());

        // Check to see that the number for FR and BR Models matches the number of the ones we inserted in the db
        System.assertEquals(true, models.size() == timeSlots.size());
    }
}