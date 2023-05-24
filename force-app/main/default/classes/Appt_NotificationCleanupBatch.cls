/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This setup Schedule uses the Custom Metadata value for Notification Purge Days Back. The Batch queries all the Notification records that have a Created date that is less than the current date and the Purge Days Back offset.  The execution method is standard, it runs the Bath process.
 */
public with sharing class Appt_NotificationCleanupBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents
{
    final static string LPREFIX = 'APPT_NOTIFICATION_CLEANUP: ';
    public final String QUERY;
    public Appt_NotificationCleanupBatch() {

        System.debug('Start Appt_NotificationCleanupBatch  default Constructor');
        // The QUERY will pull the next set of notifications to be deleted

        // get the Appointment settings 
        List<Appt_Appointment_Setting__mdt> notificationPurgeSettings = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Notification_Purge_Days_Back'];
        Integer daysBack = Integer.valueOf(notificationPurgeSettings[0].Value__c);
        String hardLimit = ' LIMIT 1000000';

        Datetime queryByDate = DateTime.now().addDays(-daysBack);

        // set the query to now for tests so that notificaitons can be found to be deleted
        if(Test.isRunningTest()) {queryByDate = DateTime.now().addDays(1);}
        
        // Get Notification objects that are older than 14 days AND are past the appointment date or cancelled/completed
        QUERY = 'SELECT Id, CreatedDate '
        +' FROM Notification__c '
        +' WHERE CreatedDate < ' + queryByDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','UTC') +' AND (Service_Appointment__r.SchedStartTime < TODAY OR Appointment_Status__c IN (\'Cancelled\',\'Completed\'))'
        + hardLimit;        
        
        System.debug('QUERY: ' + QUERY);        
      
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start Appt_NotificationCleanupBatch start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Notification__c> notifications)
    {
        System.debug('Start Appt_NotificationCleanupBatch execute');
        System.debug(notifications);
        delete notifications;

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('Stop Appt_NotificationCleanupBatch execute');
    }

    public void finish(Database.BatchableContext context)
    {
        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }
}