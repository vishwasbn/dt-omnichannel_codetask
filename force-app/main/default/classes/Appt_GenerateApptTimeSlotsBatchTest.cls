@IsTest
public class Appt_GenerateApptTimeSlotsBatchTest {
    
    @TestSetup
    public static void makeData(){

        //-- this will setup a store with 27 days of slots
        Appt_TestUtil.basicAppointment_StoreConfiguration();
        
    }

    @IsTest
    public static void testBatch() {

        List<ServiceAppointment> sas = [ SELECT Id, ServiceTerritory.Id FROM ServiceAppointment ];
        System.assertEquals(true, sas.size() > 0, 'No service appointments found');  
        System.debug('List<ServiceAppointment> sas = [ SELECT Id, ServiceTerritory.Id FROM ServiceAppointment ] : ' + sas);     

        String serviceTerritoryId = sas[0].ServiceTerritory.Id;

        List<ServiceTerritory> testTerritory = [SELECT Id, Name, ParentTerritoryId, ParentTerritory.OperatingHoursId, OperatingHoursId, OperatingHours.TimeZone, Front_Time_Slot_Configuration__c, Back_Time_Slot_Configuration__c, ParentTerritory.Front_Time_Slot_Configuration__c, ParentTerritory.Back_Time_Slot_Configuration__c, Site_Account__c, Site_Account__r.SAP_STORE_ID__c, Date_Last_Slot_Generated__c FROM ServiceTerritory WHERE id = :serviceTerritoryId];
        System.debug(testTerritory);
        if (testTerritory != null) {
            System.debug('ServiceTerritory SAP_STORE_ID__c = ' + testTerritory[0].Site_Account__r.SAP_STORE_ID__c + ', Date_Last_Slot_Generated__c = ' + testTerritory[0].Date_Last_Slot_Generated__c);

        }

        Set<Id> storeIdSet = new Set<Id>();
        for ( ServiceTerritory store: testTerritory ) { storeIdSet.add( store.Id ); }

        List<Appt_Time_Slot__c> beforeTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory[0].id];
        System.debug('beforeTimeSlots.size() = ' + beforeTimeSlots.size());

        Test.startTest();

        // Appt_GenerateCleanupApptTimeSlotsBatch.process();
        // Appt_GenerateCleanupApptTimeSlotsBatch.processGenerateUpcomingApptTimeSlots(testTerritory);

        // Appt_GenerateCleanupApptTimeSlotsBatch.processCleanupPastApptTimeSlotsAndSpots(storeIdSet);

        Id batchId = Database.executeBatch(new Appt_GenerateCleanupApptTimeSlotsBatch(), 3);
        System.debug('batchId' + batchId);

        Test.stopTest();

        List<Appt_Time_Slot__c> afterTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory[0].id];
        System.debug(afterTimeSlots.size());

        System.assert(afterTimeSlots.size() > beforeTimeSlots.size(),'Time slots were created for the store');

    }


    @isTest
    public static void testGenerateAllSlotsForStore(){
        List<ServiceAppointment> sas = [ SELECT Id, ServiceTerritory.Id FROM ServiceAppointment ];
        System.assertEquals(true, sas.size() > 0, 'No service appointments found');       

        String serviceTerritoryId = sas[0].ServiceTerritory.Id;

        ServiceTerritory testTerritory = [SELECT id, OperatingHoursId, Scheduling_Policy__c, Front_Time_Slot_Configuration__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Back_Appointment_Work_Type__c FROM ServiceTerritory WHERE id = :serviceTerritoryId];
        System.debug(testTerritory);

        List<Appt_Time_Slot__c> beforeTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory.id];
        System.debug(beforeTimeSlots.size());


        List<Appt_Time_Slot_Capacity__c> overrideList = new List<Appt_Time_Slot_Capacity__c>();
        Appt_Time_Slot_Capacity__c newOverride = new Appt_Time_Slot_Capacity__c();
        newOverride.Service_Territory__c = testTerritory.id;

        overrideList.add(newOverride);

        insert overrideList;
        System.debug(overrideList);

        Test.startTest();
        System.debug('***********START TEST*************');

        Appt_GenerateCleanupApptTimeSlotsBatch.generateAllSlotsForStore(serviceTerritoryId);
        
        System.debug('***********END TEST*************');
        Test.stopTest();

        List<Appt_Time_Slot__c> afterTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory.id];
        System.debug(afterTimeSlots.size());

        System.assert(afterTimeSlots.size() > beforeTimeSlots.size(),'Time slots were created for the store');
    }

    @isTest
    public static void testGenerateAutomatedStoreSetup(){
        List<ServiceAppointment> sas = [ SELECT Id, ServiceTerritory.Id FROM ServiceAppointment ];
        System.assertEquals(true, sas.size() > 0, 'No service appointments found');       

        String serviceTerritoryId = sas[0].ServiceTerritory.Id;
        List<String> newServiceTerritoryIds = new List<String>();
        newServiceTerritoryIds.add(sas[0].ServiceTerritory.Id);

        ServiceTerritory testTerritory = [SELECT id, OperatingHoursId, Scheduling_Policy__c, Front_Time_Slot_Configuration__c, Back_Time_Slot_Configuration__c, Front_Appointment_Work_Type__c, Back_Appointment_Work_Type__c FROM ServiceTerritory WHERE id = :serviceTerritoryId];
        System.debug(testTerritory);

        List<Appt_Time_Slot__c> beforeTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory.id];
        System.debug(beforeTimeSlots.size());


        List<Appt_Time_Slot_Capacity__c> overrideList = new List<Appt_Time_Slot_Capacity__c>();
        Appt_Time_Slot_Capacity__c newOverride = new Appt_Time_Slot_Capacity__c();
        newOverride.Service_Territory__c = testTerritory.id;

        overrideList.add(newOverride);

        insert overrideList;
        System.debug(overrideList);

        List<String> processedStoreSetupImportIds = new List<String>();

        Test.startTest();
        System.debug('***********START TEST*************');

        Appt_GenerateCleanupApptTimeSlotsBatch generateCleanupApptTimeSlotsBatch = new Appt_GenerateCleanupApptTimeSlotsBatch(newServiceTerritoryIds, processedStoreSetupImportIds, 'user.name@test.com');
        
        Database.executeBatch(generateCleanupApptTimeSlotsBatch, 3);

        System.debug('***********END TEST*************');
        Test.stopTest();

        List<Appt_Time_Slot__c> afterTimeSlots = [SELECT id, Service_Territory__c FROM Appt_Time_Slot__c WHERE Service_Territory__c = :testTerritory.id];
        System.debug(afterTimeSlots.size());

        System.assert(afterTimeSlots.size() > beforeTimeSlots.size(),'Time slots were created for the store');
    }

    @isTest
    static void setupScheduleTest(){
       
        System.debug('***********START TEST***************');
        Test.startTest();
        Appt_GenerateApptTimeSlotsBatchScheduler.setupSchedule();
        Test.stopTest();  
        System.debug('***********END TEST***************');

        CronTrigger ct =  [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1];
        System.debug(ct.CronJobDetail.Name);
        System.assert(ct.CronJobDetail.Name.contains('Appt_GenerateApptTimeSlotsBatchSchedulerTest'),'check for job to be created');

    }

}