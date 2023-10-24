@isTest
public with sharing class Appt_StoreCapacityConfigMainTest {

    @testSetup
    static void setupData() {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
    }

    @IsTest
    static void getStoresTest(){
        String searchString = 'AZP 12';

        System.debug('***Start Test***');
        Test.startTest();
        String results = Appt_StoreCapacityConfigMainController.getStores(searchString);
        Test.stopTest();
        System.debug('***End Test***');

        System.debug(results);
        System.assert(results.contains('RIP05'),'checks for store to be found');
        
        try{
            String catchResults = Appt_StoreCapacityConfigMainController.updateStoreConfig(null);
             String catchR = Appt_StoreCapacityConfigMainController.getStores(null);
        }catch(exception e){}
        
    }

    @IsTest
    static void getStoreConfigExceptionTest(){

        String serviceTerritoryId = '';
        String selectedDay = 'Monday';

        System.debug('***Start Test***');
        Test.startTest();
        String results = Appt_StoreCapacityConfigMainController.getStoreConfig(serviceTerritoryId,selectedDay);
        Test.stopTest();
        System.debug('***End Test***');
        System.debug(results);
        System.assert(results.contains('"success":false'),'checks for an exception on a store');
        
    }

    @IsTest
    static void updateStoreConfigTest(){

        ServiceTerritory testTerritory = [SELECT id, Site_Account__r.SAP_STORE_ID__c, OperatingHoursId FROM ServiceTerritory LIMIT 1];
        
        List<Appt_Time_Slot_Capacity__c> overrideList = new List<Appt_Time_Slot_Capacity__c>();

        Appt_Time_Slot_Capacity__c newCapacity = new Appt_Time_Slot_Capacity__c();        

        newCapacity.BSF_Capacity__c = 5;
        newCapacity.BSR_Capacity__c = 5;
        newCapacity.BWF_Capacity__c = 5;
        newCapacity.BWR_Capacity__c = 5;
        newCapacity.FSF_Capacity__c = 5;
        newCapacity.FSR_Capacity__c = 5;
        newCapacity.FWF_Capacity__c = 5; 
        newCapacity.FWR_Capacity__c = 5;
        newCapacity.Day_of_Week__c = 'Monday';
        newCapacity.Start_Time__c = Time.newInstance(13, 0, 0, 0);
        newCapacity.End_Time__c = Time.newInstance(13, 20, 0, 0);
        newCapacity.Service_Territory__c = testTerritory.id;

        insert newCapacity;

        Appt_Time_Slot_Capacity__c newCapacity2 = new Appt_Time_Slot_Capacity__c();        

        newCapacity2.BSF_Capacity__c = 5;
        newCapacity2.BSR_Capacity__c = 5;
        newCapacity2.BWF_Capacity__c = 5;
        newCapacity2.BWR_Capacity__c = 5;
        newCapacity2.FSF_Capacity__c = 5;
        newCapacity2.FSR_Capacity__c = 5;
        newCapacity2.FWF_Capacity__c = 5; 
        newCapacity2.FWR_Capacity__c = 5;
        newCapacity2.Day_of_Week__c = 'Tuesday';
        newCapacity2.Start_Time__c = Time.newInstance(13, 0, 0, 0);
        newCapacity2.End_Time__c = Time.newInstance(13, 20, 0, 0);
        newCapacity2.Service_Territory__c = testTerritory.id;

        insert newCapacity2;

        String effectiveDate = String.valueOf(Date.today().addDays(1).year()) + '-' + String.valueOf(Date.today().addDays(1).month()) + '-' + String.valueOf(Date.today().addDays(1).day());
 

        //String mockPayload = '{ "serviceTerritory": "'+testTerritory.id+'", "effectiveDate": "2021-11-19", "selectedDays": [ { "selectedDay": "Monday" }, { "selectedDay": "Tuesday" } ], "ApptTimeSlotCapacities": [ { "id": "a177c000001Hwx8AAC", "BSF_Capacity__c": 1, "BSR_Capacity__c": 2, "BWF_Capacity__c": 0, "BWR_Capacity__c": 0, "FSF_Capacity__c": 1, "FSR_Capacity__c": 2, "FWF_Capacity__c": 0, "FWR_Capacity__c": 1, "Day_of_Week__c": "Monday", "Start_Time__c": "08:00:00.000Z", "End_Time__c": "08:15:00.000Z" }, { "id": "a177c000001Hwx8AAC", "BSF_Capacity__c": 1, "BSR_Capacity__c": 2, "BWF_Capacity__c": 0, "BWR_Capacity__c": 0, "FSF_Capacity__c": 1, "FSR_Capacity__c": 2, "FWF_Capacity__c": 0, "FWR_Capacity__c": 1, "Day_of_Week__c": "Monday", "Start_Time__c": "08:15:00.000Z", "End_Time__c": "08:30:00.000Z" }, { "id": "a177c000001Hwx8AAC", "BSF_Capacity__c": 1, "BSR_Capacity__c": 2, "BWF_Capacity__c": 0, "BWR_Capacity__c": 0, "FSF_Capacity__c": 1, "FSR_Capacity__c": 2, "FWF_Capacity__c": 0, "FWR_Capacity__c": 1, "Day_of_Week__c": "Monday", "Start_Time__c": "08:30:00.000Z", "End_Time__c": "08:45:00.000Z" }, { "id": "a177c000001Hwx8AAC", "BSF_Capacity__c": 1, "BSR_Capacity__c": 2, "BWF_Capacity__c": 0, "BWR_Capacity__c": 0, "FSF_Capacity__c": 1, "FSR_Capacity__c": 2, "FWF_Capacity__c": 0, "FWR_Capacity__c": 1, "Day_of_Week__c": "Monday", "Start_Time__c": "08:45:00.000Z", "End_Time__c": "09:00:00.000Z" } ] }';
        String mockPayload = '{ "serviceTerritory": "'+testTerritory.id+'", "effectiveDate": "'+effectiveDate +'", "selectedDays": [ { "selectedDay": "Monday" }, { "selectedDay": "Tuesday" } ], "ApptTimeSlotCapacities": [ { "id": "a177c000001Hwx8AAC", "BSF_Capacity__c": 1, "BSR_Capacity__c": 2, "BWF_Capacity__c": 0, "BWR_Capacity__c": 0, "FSF_Capacity__c": 1, "FSR_Capacity__c": 2, "FWF_Capacity__c": 0, "FWR_Capacity__c": 1, "Day_of_Week__c": "Monday", "Start_Time__c": "13:00:00.000Z", "End_Time__c": "13:20:00.000Z" } ] }';

        System.debug('***Start Test***');
        Test.startTest();
        String results = Appt_StoreCapacityConfigMainController.updateStoreConfig(mockPayload);
        Test.stopTest();
        System.debug('***End Test***');
        System.debug(results);
        System.assert(results.contains('"success":true'),'checks for an successful update');        
        
    }
}