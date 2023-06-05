/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This setup Schedule uses the Custom Metadata values for the CRON expression and the Appt Reminder Start Time.  The substution of the calculated hours value into the CRON expression tag <hour> is fairly common in this deck.  The Schedule created is based on the users timezone adjusted to EDT(GMT-4) to HST(GMT-10).  The Schedule runs on the hour from the Reminder Start Time EDT to the Reminder Start Time HST.  The execution method is standard, it runs the Bath process with a job size of "Appt Reminder Batch Size" (currently 1000).
 */
public class Appt_AppointmentReminderScheduler implements Schedulable 
{

    final static string LPREFIX = 'Appt_AppointmentReminderScheduler: ';

    // constructor is used but not populated
    public Appt_AppointmentReminderScheduler() 
    {
        System.debug(LPREFIX + ' constructor');
    }

    //---Setup the schedule for the process
    public static void setupSchedule()
    {

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - START');
        String scheduleName = 'Appt_AppointmentReminderScheduler ';

        // get the Appointment settings for the Reminders
        List<Appt_Appointment_Setting__mdt> apptSettingList = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName LIKE 'Appt_Reminder_%'];
        // map the settings based on the developerName
        Map<String, Appt_Appointment_Setting__mdt> apptSettingMap = new Map<String, Appt_Appointment_Setting__mdt>();
        for (Appt_Appointment_Setting__mdt apptSetting: apptSettingList) 
        {
            apptSettingMap.put(apptSetting.DeveloperName, apptSetting);
            System.debug( LPREFIX + ' Reading ' + apptSetting.DeveloperName + ' : ' + apptSetting.Value__c);
        }

        try {
            // get the CRON Expression template
            String cronExp = apptSettingMap.get('Appt_Reminder_CronExpTemplate').Value__c;

            // get the start times for from the Custom Metadata
            String startStr = apptSettingMap.get('Appt_Reminder_Start_Time').Value__c;

            if ( Test.isRunningTest() )
            {
                cronExp = '0 0 <hour> ? * SUN-FRI *'; // day before reminder, workdays Mon-Sat, so Sun-Fri
                startStr = '0700';
                scheduleName = 'Appt_AppointmentReminderSchedulerTest ';
            }

            if ( cronExp == null || cronExp == '' )
            {
                System.debug( LPREFIX + 'No valid CRON Expression values, no schedules created');
            }
            else 
            {
                // The Schedules will be setup once an hour starting with UTC-4 (EDT) for the  
                //	the Start Time ( has to cover EDT & EST thru HST)

                // Get the hour portion of the start time string
                Integer startHour = Integer.valueOf( startStr.left(2) );
                TimeZone tz = UserInfo.getTimeZone(); // get the current users timezone
                //  used to base the schedule on the local user, since the schedules are local time

                // creates start hour in GMT for EDT (GMT-4)
                Datetime gmtStart = DateTime.newInstanceGMT( DateTime.now().date(), Time.newInstance(( startHour + 4 ), 0, 0, 0));

                // adjust the GMT start time to encompass EDT(-4) to HST(-10) local time  { 7 timezones, 6 breaks }
                String cronStr = cronExp.replace( '<hour>', gmtStart.format('H', tz.getID() ) + '-' + gmtStart.addHours( 6 ).format('H', tz.getID() ) );
                System.debug(LPREFIX + ' cronStr: ' + cronStr);

                // submit the new schedule to the system
                System.schedule(scheduleName + startHour + ' at: ' + cronStr, cronStr, new Appt_AppointmentReminderScheduler());

            }
        } catch (TypeException e) {
            System.debug( LPREFIX + 'Processing time is not a valid value: ' + e.getMessage());
        } catch (Exception e) {
            System.debug( LPREFIX + 'Exception: ' + e.getMessage());
        }

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    }

    // when the system executes the scheduled task this method runs the Appt_AppointmentReminderBatch
    public void execute(SchedulableContext sc) {

        System.debug(' >>>>>>> Service Appointment Reminder execute ');

        // the custom metadata for the Appointment Reminder batch size
        List<Appt_Appointment_Setting__mdt> apptSettingList = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Appt_Reminder_Batch_Size'];

        Id batchId = Database.executeBatch(new Appt_AppointmentReminderBatch(), Integer.valueOf( apptSettingList[0].Value__c ) );
        System.debug( 'batchId: ' + batchId );

    }

}