/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   The Batch class creates a query to get all Notifications with Created Date not older than 30 days, Initial eMail send status of 'Invalid Order Number' OR Initial PE SMS send status of 'Invalid Order Number' AND has a Valid Order Number (Notification formula).  When the Batch is executed, all records have Initial eMail send status set to Pending, Initial PE SMS send status set to Failure, and Invoice status set to Pending.  Once the records are set to trigger a resend, a callout for each notification is performed to obtain the Hybris, Invoice, Layaway, or Quote Invoice detail information.  The Invoice detail information is packaged into a Invoice Detail Model payload and attached to the Notification record.  The Notification Invoice status is changed to Successful (or Error if the Batch failed to retrieve and Invoice).  Finally the Batch updates the Notification records that had Invoice payloads attached.  There was a switch added based on the custom metadata 'Use_SFMC_Email' value that prevents the callout from occurring, but allows the records to be updated with the values needed to trigger a resend.  There is also log metering added for load testing;
 */
public with sharing class Appt_NotificationDelayedSendBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Database.RaisesPlatformEvents
{

    final static string LPREFIX = 'Appt_NotificationDelayedSendBatch: ';
    public final String QUERY;
    public final String searchStatus = Appt_ConstantValues.NOTIFICATION_STATUS_INVAILD_ORDER_NUMBER;

    public Appt_NotificationDelayedSendBatch() {

        System.debug( 'Start ' + LPREFIX + ' default Constructor');

        // get the Appointment settings 
        List<Appt_Appointment_Setting__mdt> notificationPurgeSettings = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Notification_Send_Days_Back'];
        Integer daysBack = Integer.valueOf(notificationPurgeSettings[0].Value__c);
        
        // create the date to compare with CreateDate in the Query
        Datetime queryByDate = DateTime.now().addDays(-daysBack);

        // set the query to now for tests so that notificaitons can be found
        if(Test.isRunningTest()) {queryByDate = DateTime.now().addDays(-10);}
        
        QUERY = 'SELECT Id, API_Callout_Order_Type__c, Work_Order__r.Order_Date__c, Order_Number__c, SAP_Store_Id__c, Invoice_Status__c, Invoice_Payload__c, Invoice_Date__c, Invoice_Error__c, Initial_Email_Send_Status__c, Initial_PE_SMS_Send_Status__c, Last_Error_Message__c FROM Notification__c WHERE CreatedDate > '+ queryByDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','UTC') +' AND (Initial_PE_SMS_Send_Status__c = \''+searchStatus+'\' OR Initial_Email_Send_Status__c = \''+searchStatus+'\') AND Has_Valid_Order_Number__c = true ORDER BY CreatedDate DESC ';
        System.debug('QUERY: ' + QUERY);        
      
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start ' + LPREFIX + ' start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Notification__c> notifications)
    {
        System.debug('Start ' + LPREFIX + ' execute');

        notifications = Appt_NotificationUtil.getUpdatedNotificaitonObject(notifications);

        System.debug('notifications = ' +notifications);
        // create a list of email notificaiton to update the order info
        List<Notification__c> updateEmail = new List<Notification__c>();
        // create a list of sms notifications to update
        List<Notification__c> updateSms = new List<Notification__c>();

        for(Notification__c notify : notifications){
            // for email notificaitons change the status to pending to trigger a resend 
            if(notify.Initial_Email_Send_Status__c == searchStatus){
                // Update the email payload now that we have the correct order number
                Appt_NotificationUtil.buildEmailPayload(notify);

                // add to the list to have order information refreshed
                updateEmail.add(notify);
            }

            // Set the status to re-trigger the SMS
            if(notify.Initial_PE_SMS_Send_Status__c == searchStatus){
                notify.Initial_PE_SMS_Send_Status__c = Appt_ConstantValues.NOTIFICATION_STATUS_FAILURE;
                Notification__c updateNote = new Notification__c(Id = notify.Id, Initial_PE_SMS_Send_Status__c = notify.Initial_PE_SMS_Send_Status__c);
                // add to the list to have sms refreshed
                updateSms.add(updateNote);
            }
        }

        // trigger the order data to be updated so the email can be sent out.

        //---06.09.22.SS - Switch to new SFMC Email System
        Boolean useSFMCEmail = Test.isRunningTest() ? false : Appt_SettingUtil.getSettingBooleanValue( 'Use_SFMC_Email');
        if (useSFMCEmail)
        {
            System.debug(LPREFIX + 'Using new SFMC Email, no need for this processing');
            update notifications;
        }else{
            if(updateEmail.size() > 0){
                Appt_EmailNotifyBatch.executeEmailNotify(updateEmail);
            }          
            if(updateSms.size() > 0){
                update updateSms;
            }
        }

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug(LPREFIX +'Start ' + LPREFIX + ' execute');
    }  // End of execute()

    public void finish(Database.BatchableContext context)
    {
        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }

}