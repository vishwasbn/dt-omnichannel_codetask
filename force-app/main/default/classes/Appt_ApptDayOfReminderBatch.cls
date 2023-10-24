/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have DayOf_Notifiication_Sent__c equal false, Status of "Scheduled" or "Confirmed", Notification_Appointment__c equal true, Timezone is greater than the current Timezone, Scheduled Start time is TODAY.  The Batch sets the records DayOf_Notifiication_Sent__c to true and creates a Notification record of type JT_REMINDER for channel SMS.
 */
public class Appt_ApptDayOfReminderBatch  implements Database.Batchable<sObject>, Database.RaisesPlatformEvents
{
    public final String QUERY;
    final static string LPREFIX = 'LOG Appt_ApptDayOfReminderBatch: ';

    // Appt_ApptDayOfReminderBatch class constructor    
    public Appt_ApptDayOfReminderBatch()
    {
        System.debug('Start Appt_ApptDayOfReminderBatch default Constructor');
        // the QUERY will pull the next set of Reminders to be process based on TimeZone and ScheduleStartTime

        // the batch will set the Reminder sent on the Service Appointment to signal completion

        Datetime currentTimeUtc = Datetime.now();
        
        //SO-891 send Notification remainder till 48 hrs - Start Add
		Datetime dt_calculateHrs;
		Integer i_maxhrs = Integer.valueOf( Appt_SettingUtil.getSettingValue( Appt_ConstantValues.MAX_NOTIFICATION_REMAINDER_HRS) );
        dt_calculateHrs = currentTimeUtc.addhours(i_maxhrs);
        System.debug('**dt_calculateHrs: ' + dt_calculateHrs+ ' **i_maxhrs: '+ i_maxhrs);
		//SO-891 send Notification remainder till 48 hrs - End Add

        // create current UTC time for testing
        if(Test.isRunningTest()){
            currentTimeUtc = Datetime.newInstanceGMT(currentTimeUtc.yearGmt(), currentTimeUtc.monthGmt(), currentTimeUtc.dayGmt(), 17, 00, 00); 
                // UTC ... PDT 7am
        } 
        System.debug('currentTimeUtc: ' + currentTimeUtc);

        // get the Appointment settings for the Reminders
        List<Appt_Appointment_Setting__mdt> apptSettingList = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName LIKE 'Appt_Reminder_%'];

        // map the settings based on the developerName
        Map<String, Appt_Appointment_Setting__mdt> apptSettingMap = new Map<String, Appt_Appointment_Setting__mdt>();
        for (Appt_Appointment_Setting__mdt apptSetting: apptSettingList) 
        {
            apptSettingMap.put(apptSetting.DeveloperName, apptSetting);
        }

        // get the start time hour
        Integer startHour = Integer.valueOf( apptSettingMap.get('Appt_Reminder_Day_Of_Start_Time').Value__c.left(2) ); // i.e. 10
        System.debug('startHour: ' + startHour);

        // get the next time zone
        Integer timeZone = Appt_AppointmentReminderBatch.getNextTimeZone(currentTimeUtc, startHour);
        System.debug('Appt_ApptDayOfReminderBatch::timeZone: ' + timeZone);

        if (timeZone != null)
        {
            // get all the records with Scheduled Start Times for tomorrow in the time zone that is at the start hour
            QUERY = 'SELECT Id, Status, Notification_Appointment__c, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Reminder_Notification_Sent__c FROM ServiceAppointment WHERE DayOf_Notifiication_Sent__c = false AND ( Status = \'Scheduled\' OR Status = \'Confirmed\' ) AND Notification_Appointment__c = true AND Timezone_Offset__c >= ' + timeZone + ' AND SchedStartTime = TODAY ORDER BY Timezone_Offset__c DESC';
            System.debug('QUERY: ' + QUERY);
        }
        else {
            QUERY = 'SELECT Id FROM ServiceAppointment LIMIT 0';
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start Appt_ApptDayOfReminderBatch start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope)
    {
        System.debug('Start Appt_ApptDayOfReminderBatch execute');

        Map<id,String> notificaitonMap = new Map<id,String>();
        List<ServiceAppointment> apptList = new List<ServiceAppointment>();
        for (ServiceAppointment appt: scope ) 
        {            
            notificaitonMap.put(appt.id, 'JT_REMINDER');
            appt.DayOf_Notifiication_Sent__c = true;
            apptList.add(appt);
        }

        System.debug( 'Appt_ApptDayOfReminderBatch Create Reminder - selected notificaitons');
        System.debug(notificaitonMap);

        // send notifications to method to be processed
        if(notificaitonMap.size() > 0){
            // Pass notificaiton map and the type of notificaiton 
            Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION','SMS');
            update apptList;
        }

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('Stop Appt_ApptDayOfReminderBatch execute');
    }

    public void finish(Database.BatchableContext bc)
    {
        Id batchId = bc.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }
}