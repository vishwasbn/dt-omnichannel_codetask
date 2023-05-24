@isTest
public with sharing class Appt_StoreConfigUpdateProcessTest {

    @testSetup
    static void setupData() {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
    }

    @IsTest
    static void updateStoreProcessTest(){
        
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

        Appt_UpdateStoreConfig storesConfig = new Appt_UpdateStoreConfig();
        storesConfig = (Appt_UpdateStoreConfig) JSON.deserialize(mockPayload, Appt_UpdateStoreConfig.class);
        Boolean testResult = Appt_StoreConfigUpdateProcess.updateStoreProcess(storesConfig);

        Test.stopTest();
        System.debug('***End Test***');
        System.debug(storesConfig);    
        System.assert(storesConfig.selectedDays[1].selectedDay == 'Tuesday', 'checks for days correctly added');

        System.assertEquals(true, testResult, 'check for successful process');

        Appt_Time_Slot_Capacity__c testCapacityUpdate = [SELECT id, BSF_Capacity__c, Start_Time__c, End_Time__c FROM Appt_Time_Slot_Capacity__c WHERE id = :newCapacity2.id];
        System.debug(testCapacityUpdate);

        System.assert(testCapacityUpdate.BSF_Capacity__c == 1, 'checks for BSF_Capacity__c update');

        
    }
}