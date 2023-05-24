@IsTest
public with sharing class Appt_StoreConfigsTest {
    @testSetup
    static void setupData() {
        List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
    }

    @IsTest
    static void Appt_StoreConfigsCreateObj(){        

        List<ServiceTerritory> testStore = [SELECT id, OperatingHoursId FROM ServiceTerritory LIMIT 1];       
        
        System.debug('***Start Test***');
        Test.startTest();
        Appt_StoreConfigs testConfig = new Appt_StoreConfigs(testStore[0].id, 'Monday');
        Appt_StoreConfigs testConfig2 = new Appt_StoreConfigs();
        Test.stopTest();
        System.debug('***End Test***');
        System.debug(testConfig);
        System.assertEquals(null, testConfig2.serviceTerritory, 'check for empty object');
        System.assertEquals('8:00AM - 6:00PM', testConfig.days[0].operatingHours, 'check for empty object');
        
        
    }
}