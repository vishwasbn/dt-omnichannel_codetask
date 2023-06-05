public with sharing class Appt_CapacityUpdateHistorySchedulable implements Schedulable {

    public static void execute(SchedulableContext sc) {
        process();
    }

    public static void process() {
        // we have set the batch size to 4 to help ensure that you don't run into limit issues when querying and processing all the Appt_Capacity_Update_History__c records
        Id batchId = Database.executeBatch(new Appt_CapacityUpdateHistoryBatch(),4);
    }

    // Default schedule that is set to run every night 
    public static void setupschedule() {
        String scheduleName = 'Appt_CapacityUpdateHistoryBatch';
        if(Test.isRunningTest()){scheduleName = 'Appt_CapacityUpdateHistoryBatchTest';}
        System.schedule(scheduleName+' at 00 min','0 0 2 * * ?', new Appt_CapacityUpdateHistorySchedulable());
    }
}