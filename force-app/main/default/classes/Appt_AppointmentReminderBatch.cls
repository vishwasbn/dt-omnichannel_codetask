/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have Reminder_Notification_Sent__c equal false, Status of "Scheduled" or "Confirmed", Notification_Appointment__c equal true, Timezone is greater than the current Timezone, Scheduled Start time is TOMORROW.  The Batch sets the records Reminder_Notification_Sent__c to true and creates a Notification record of type APPT_REMINDER for channel SMS & EMAIL.
 */
public class Appt_AppointmentReminderBatch  implements Database.Batchable<sObject>, Database.RaisesPlatformEvents
{
    public final String QUERY;
    final static string LPREFIX = 'LOG Appt_AppointmentReminderBatch: ';

    // Appt_AppointmentReminderBatch class constructor
    public Appt_AppointmentReminderBatch() 
    {
        System.debug('Start Appt_AppointmentReminderBatch default Constructor');
        // the QUERY will pull the next set of Reminders to be process based on TimeZone and ScheduleStartTime

        // the batch will set the Reminder sent on the Service Appointment to signal completion

        Datetime currentTimeUtc = Datetime.now();
        //***********SO-891 send Notification remainder booked after 48 hrs - Start Add
        Datetime dtCalculated48Hrs = Datetime.now();
        //As per the SO-891 requirement we need to check if the appointment record is created date and scheduled date difference is 48 hrs. 
        //So already the batchexecution is 24 hrs behind the schedule date (TOMORROW).
        //By still subrtacting '-24 hrs' from current time the calculation will be for 48 hrs to scheduled start time.
		dtCalculated48Hrs = dtCalculated48Hrs.addhours(-24);
		String strFormated48hrsDate = String.valueOf(dtCalculated48Hrs.dateGmt())+'T'+String.valueOf(dtCalculated48Hrs.timeGmt());
        //***********SO-891 send Notification remainder booked after 48 hrs - End Add
        
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
        Integer startHour = Integer.valueOf( apptSettingMap.get('Appt_Reminder_Start_Time').Value__c.left(2) ); // i.e. 10
        System.debug('startHour: ' + startHour);

        // get the next time zone
        Integer timeZone = getNextTimeZone(currentTimeUtc, startHour);
        System.debug('Appt_AppointmentReminderBatch::timeZone: ' + timeZone);

        if (timeZone != null){    
           // get all the records with Scheduled Start Times for tomorrow in the time zone that is at the start hour
           // SO-891 added if condition for is Runing test.
           if(Test.isRunningTest()){
           	QUERY = 'SELECT Id, Status, Notification_Appointment__c, ServiceTerritoryId, Work_Order__c, Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Reminder_Notification_Sent__c FROM ServiceAppointment WHERE Reminder_Notification_Sent__c = false AND ( Status = \'Scheduled\' OR Status = \'Confirmed\' ) AND Notification_Appointment__c = true AND Timezone_Offset__c >= ' + timeZone + ' AND SchedStartTime = TOMORROW ORDER BY Timezone_Offset__c DESC';
           	System.debug('**QUERY: ' + QUERY);
           }
           else{
             // SO-891 Update in the query addedd CreatedDate < '+str_formatedDate+
             QUERY = 'SELECT Id, Status, Notification_Appointment__c, ServiceTerritoryId, Work_Order__c,Timezone_Offset__c, Activity_Type__c, Consult_Start_Time__c, Back_Office_Start_Time__c, SchedStartTime, Reminder_Notification_Sent__c FROM ServiceAppointment WHERE Reminder_Notification_Sent__c = false AND ( Status = \'Scheduled\' OR Status = \'Confirmed\' ) AND Notification_Appointment__c = true AND Timezone_Offset__c >= ' + timeZone + ' AND SchedStartTime = TOMORROW AND CreatedDate < '+strFormated48hrsDate+ ' ORDER BY Timezone_Offset__c DESC';
           	 System.debug('**QUERY: ' + QUERY);
           }
           
        }
        else {
            QUERY = 'SELECT Id FROM ServiceAppointment LIMIT 0';
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start Appt_AppointmentReminderBatch start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope)
    {
        System.debug('Start Appt_AppointmentReminderBatch execute');

        Map<id,String> notificaitonMap = new Map<id,String>();
        List<ServiceAppointment> apptList = new List<ServiceAppointment>();
        
        for (ServiceAppointment appt: scope ){   
             	notificaitonMap.put(appt.id, Appt_ConstantValues.NOTIFICATION_APPT_REMINDER);
            	appt.Reminder_Notification_Sent__c = true;
            	apptList.add(appt);
        }

        System.debug( 'Appt_AppointmentReminderBatch Create Reminder - selected notificaitons');
        System.debug(notificaitonMap);

        // send notifications to method to be processed
        if(notificaitonMap.size() > 0){
            // Pass notificaiton map and the type of notificaiton 
            Appt_NotificationUtil.createServiceAppointmentNotificaitons(notificaitonMap,'TRANSACTION','SMS, EMAIL');
            update apptList;
        }

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('Stop Appt_AppointmentReminderBatch execute');
    }

    public void finish(Database.BatchableContext bc)
    {
        Id batchId = bc.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }

    public static Integer getNextTimeZone (Datetime currentTimeUtc, Integer startHour)
    {
        Set<String> timeZoneNames = new Set<String> {'Eastern', 'Central', 'Mountain', 'Pacific', 'Alaska', 'Hawaii'};
        Integer timeZone;
        // i.e. currentTimeUTC equal 2022-06-20 19:47:25  (12:00 MST)

        for (String tzName: timeZoneNames)
        {
            // get the Daylight savings adjusted GMT offset for the named timezone
            Integer tz = getTimeZoneOffset(tzName); // i.e. (Eastern) equal -4 EDT
            System.debug('timeZoneOffset: ' + tz);

            // local time for timezone being checked, make sure it is on the right day
            Datetime localDatetime = currentTimeUtc.addHours(tz); // i.e. 2022-06-20 15:47:25
            System.debug('localDatetime: ' + localDatetime);

            // create a datetime for the timezone date and the start hour
            Datetime processingDatetime = Datetime.newInstanceGMT( localDatetime.dateGmt(), Time.newInstance( startHour, 00, 00, 00 ) );
            System.debug('processingDatetime: ' + processingDatetime); // i.e.  2022-06-20 10:00:00
    
                // shift process time for GMT
            Datetime processingUTC = processingDatetime.addHours( (tz * -1) );  // i.e. 4

            // update the return timezone if current time is within the update window
            System.debug('processingUTC: ' + processingUTC); // i.e. 2022-06-20 14:00:00

            //  i.e. equal 2022-06-20 19:47:25 UTC  (12:00 MST)  >=  2022-06-20 14:00:00 UTC
            if (currentTimeUtc >= processingUTC){
                System.debug('next timeZone: ' + tz);
                timeZone = tz;
            } else {
                system.debug('no longer processing');
                break;
            }
        }

        return timeZone;
    }
    

    public static Boolean isDST(Integer day, Integer month, Integer dow)
    {
        //January, february, and december are out.
        if (month < 3 || month > 11) { return false; }
        //April to October are in
        if (month > 3 && month < 11) { return true; }
        Integer previousSunday = day - dow; // day minus dayOfWeek
        //In march, we are DST if our previous sunday was on or after the 8th.
        if (month == 3) { return previousSunday >= 8; }
        //In november we must be before the first sunday to be dst.
        //That means the previous sunday must be before the 1st.
        return previousSunday <= 0;
    }


    private static Integer getTimeZoneOffset(String timeZoneStr)
    {
        Boolean isDST = isDST(Datetime.now().day(), Datetime.now().month(), Integer.valueOf( Datetime.now().format('u') ) );
        Integer timeZoneOffset;

        switch on timeZoneStr {
            when 'Eastern' {
                timeZoneOffset = (isDST) ? -4 : -5; // 4am 
            }
            when 'Central' {
                timeZoneOffset = (isDST) ? -5 : -6; // 5am
            }
            when 'Mountain' {
                timeZoneOffset = (isDST) ? -6 : -7; // 6am
            }
            when 'Pacific' {
                timeZoneOffset = (isDST) ? -7 : -8; // 7am
            }
            when 'Alaska' {
                timeZoneOffset = (isDST) ? -8 : -9; // 8am
            }
            when 'Hawaii' {
                timeZoneOffset = -10; // 10am
            }
            when else {
                // 'getTimeZoneOffset() Timezone Id is an invalid value'
                throw new InvalidParameterValueException('Timezone Id', timeZoneStr);            
            }
        }
        return timeZoneOffset;
    }    
    

}