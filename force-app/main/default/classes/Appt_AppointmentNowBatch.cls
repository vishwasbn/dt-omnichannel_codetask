/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have Now_Notification_Sent__c equal false, Status of "Scheduled" or "Confirmed", Scheduled Start time is greater than the current time and less than current time plus "Now Lead Time Minutes".  The Batch sets the records Now_Notification_Sent__c to true and creates a Notification record of type APPT_NOW for channel SMS.
 */
public class Appt_AppointmentNowBatch   implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents
{
    // The Lead Minutes is a Custom Metadata value in Appt_Appointment_Setting__mdt.Appt_Now_Lead_Time_Minutes, referenced by Appt_ConstantValues.NOW_LEAD_MINUTES
    //      It is an integer value for the minutes between the execution of the Batch process and the duration of the sample period for the QUERY.
    final static string LPREFIX = 'LOG Appt_AppointmentNowBatch: ';

    public final String QUERY;
    public Appt_AppointmentNowBatch()
    {
        Integer nowLeadTimeMinutes = Integer.valueOf( Appt_SettingUtil.getSettingValue( Appt_ConstantValues.NOW_LEAD_MINUTES) );
        Datetime currentTimeUtc = Datetime.now();
        System.debug('currentTimeUtc: ' + currentTimeUtc);

        // calculate the endpoint (To) of the search, take the current hours subtract from the desired time then add to the current Datetime
        Datetime scheduledTo = currentTimeUtc.addMinutes( nowLeadTimeMinutes );
        System.debug('scheduledTo: ' + scheduledTo);

        QUERY = 'SELECT Id, Status, Notification_Appointment__c, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Now_Notification_Sent__c FROM ServiceAppointment WHERE Now_Notification_Sent__c = false AND ( Status = \'Scheduled\' OR Status = \'Confirmed\' ) AND Notification_Appointment__c = true AND SchedStartTime >= ' + currentTimeUtc.format('yyyy-MM-dd\'T\'HH:mm:\'00Z\'','UTC') + ' AND SchedStartTime <= ' + scheduledTo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','UTC') ;
        System.debug('QUERY: ' + QUERY);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug( LPREFIX + 'start');
        System.debug( LPREFIX + 'QUERY: ' + QUERY);
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope)
    {
        System.debug( LPREFIX + 'stat execute');

        Map<id,String> notificaitonMap = new Map<id,String>();
        List<ServiceAppointment> apptList = new List<ServiceAppointment>();
        for (ServiceAppointment appt: scope ) 
        {            
            notificaitonMap.put(appt.id, Appt_ConstantValues.NOTIFICATION_APPT_NOW);
            appt.Now_Notification_Sent__c = true;
            apptList.add(appt);
        }

        System.debug( LPREFIX + 'Create Now Notifications - selected notificaitons');
        System.debug(notificaitonMap);

        // send notifications to a future method to be processed
        if(notificaitonMap.size() > 0){
            String notificaionTypes = Appt_SettingUtil.getSettingValue( Appt_ConstantValues.NOW_NOTIFICATION_TYPES );
            // Pass notificaiton map and the type of notificaiton 
            Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION', notificaionTypes);
            update apptList;
        }

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug( LPREFIX + 'stop execute');
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