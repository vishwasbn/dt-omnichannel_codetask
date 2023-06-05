@IsTest
public with sharing class Appt_CapUpHistBatchTest {

    @isTest static void test() {
        //List<ServiceAppointment> servAppts =  Appt_TestUtil.basicAppointment_StoreConfiguration();
        OperatingHours opHours = new OperatingHours();
        opHours.Name = 'Test Marketplace Op Hours';
        system.debug('*** Operating Hours: ' + opHours);
        insert opHours;
        List<OperatingHours> testHours= [SELECT ID FROM OperatingHours ORDER BY CreatedDate DESC LIMIT 1];   

        ServiceTerritory territory = new ServiceTerritory();
        territory.Name = 'Test Marketplace Batch Territory';
        territory.OperatingHoursId = testHours[0].ID;
        system.debug('*** ServiceTerritory: ' + territory);
        insert territory;

        List<ServiceTerritory> testStore = [SELECT ID, Total_Appt_Capacity_Update_History__c FROM ServiceTerritory ORDER BY CreatedDate DESC LIMIT 1];
        String testStoreId = testStore[0].ID;

        List<Appt_Capacity_Update_History__c> capList = new List<Appt_Capacity_Update_History__c>();
        for (Integer i=0;i<9600;i++) {
            capList.add(new Appt_Capacity_Update_History__c(Service_Territory__c = testStoreId));
            //System.debug('***Capacity Recs: ' + i);
        }
        System.debug('***Capacity List: ' + capList);
        insert capList;


        System.debug('***Start Test***');
        Test.startTest();
        Appt_CapacityUpdateHistoryBatch acuhb = new Appt_CapacityUpdateHistoryBatch();
        Id batchId = Database.executeBatch(acuhb);
        Test.stopTest();
        System.debug('***End Test***');

        // after the testing stops, assert records were updated properly
        System.assertEquals(0, [select count() from Appt_Capacity_Update_History__c where Service_Territory__c = :testStoreId]);
    }

}