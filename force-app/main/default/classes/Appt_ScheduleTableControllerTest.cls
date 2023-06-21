@isTest
public with sharing class Appt_ScheduleTableControllerTest {
    public Appt_ScheduleTableControllerTest() {
        
    }
    
    @testSetup
    static void setupData() {
        // setup the Account ... Territory ... Resource ... Appoitments... 
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        System.assertEquals(2, servAppts.size(), 'There are not 2 Service Appointments present (tag 1)');
    }
    
    
    @isTest
    static void getAppointmentsTest(){
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        
        // Should be 2 appts in sf test, both belonging to the same service territory
        List<ServiceAppointment> appts = [SELECT Id, ServiceTerritory.Id, ServiceTerritory.Site_Account__r.SAP_STORE_ID__c FROM ServiceAppointment];
        System.assertEquals(2, appts.size(), 'There are not 2 Service Appointments present ');
        
        String storeId = appts[0].ServiceTerritory.Site_Account__r.SAP_STORE_ID__c;
        
        List<Appt_Time_Slot__c> frTimeSlots = [SELECT Id, Service_Territory__r.Id FROM Appt_Time_Slot__c WHERE Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :storeId AND Type__c='Front Room' AND  Date__c=:currentDate];
        List<Appt_Time_Slot__c> brTimeSlots = [SELECT Id, Service_Territory__r.Id FROM Appt_Time_Slot__c WHERE Service_Territory__r.Site_Account__r.SAP_STORE_ID__c = :storeId AND Type__c='Back Room' AND Date__c=:currentDate];
        
        System.assertEquals(true, frTimeSlots.size() != 0, 'There are no time slots present');
        System.assertEquals(true, brTimeSlots.size() != 0, 'There are no time slots present');
        
        List<Appt_ScheduleModel> frModels = new List<Appt_ScheduleModel>();
        List<Appt_ScheduleModel> brModels = new List<Appt_ScheduleModel>();
        
        String frSlotsJson = Appt_ScheduleTableController.getAppointments(storeId, currentDate, currentDate, 'Front Room');
        String brSlotsJson = Appt_ScheduleTableController.getAppointments(storeId, currentDate, currentDate, 'Back Room');
        
        // FR Models and BR Models that are retrieved from the ScheduleTableController
        frModels = (List<Appt_ScheduleModel>) JSON.deserialize(frSlotsJson, List<Appt_ScheduleModel>.class);
        brModels = (List<Appt_ScheduleModel>) JSON.deserialize(brSlotsJson, List<Appt_ScheduleModel>.class);
        
        System.debug('frTimeSlots size = ' +frTimeSlots.size() +'\nfrModels size = ' +frModels.size());
        System.debug('brTimeSlots size = ' +brTimeSlots.size() +'\nbrModels size = ' +brModels.size());
        
        // Check to see that the number for FR and BR Models matches the number of the ones we inserted in the db
        System.assertEquals(true, frModels.size() == frTimeSlots.size());
        System.assertEquals(true, brModels.size() == brTimeSlots.size());
        
    }
    
    @isTest
    static void Appt3_getFunctionalDatesTest()
    {
        
        System.debug('***********START TEST***************');
        Test.startTest();
        Date currentDate = (  Datetime.now().format('u') == '7' ) ? Date.today().addDays(1) : Date.today();
        List<String> result = Appt_ScheduleTableController.getFunctionalDates('1235',currentDate);   
        Test.stopTest();  
        
        System.debug('***********END TEST***************');
        
        System.debug('result size'+ result.size());
        System.assertEquals(true, result.size()>0,'Functional dates for calendar');
        
    }
    @isTest
    static void getStoreHoursTest(){

        System.debug('***********START TEST***************');
        Test.startTest();
        String result = Appt_ScheduleTableController.getStoreHours('1235');       
        
        Test.stopTest();  
        
        System.debug('***********END TEST***************');
        System.debug(result);
        System.assert(result.contains('"endTimeHour":18,"dayOfWeek":"Monday"'),'Store Hours were returned correctly for Monday');
    }
}