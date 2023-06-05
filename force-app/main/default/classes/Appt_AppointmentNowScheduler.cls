/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This setup Schedule uses the Custom Metadata values for the CRON expression and the Now Lead Minutes.  There is a more extensive check to see that the CRON expression is populated and the Now Lead Minutes can evenly divide up the hour.  If the CRON express is empty or the Now Lead Minutes is not divisible an error log is created and the processing is terminated.  The substution of the Now Lead Minutes value into the CRON expression tag <minutes> is fairly common in this deck.  The Schedules created are Now Lead Minutes a part.  The execution method is standard, it runs the Bath process.
 */
public class Appt_AppointmentNowScheduler implements Schedulable 
{
    // The CRON Expression is a Custom Metadata value in Appt_Appointment_Setting__mdt.Appt_Now_CronExpTemplate, referenced by Appt_ConstantValues.NOW_CRON_EXP
    //      It is a CRON expression defining the Weekdays and Hours for the Schedule, with a <minutes> tag that will be replaced by the Lead Minutes
    // The Lead Minutes is a Custom Metadata value in Appt_Appointment_Setting__mdt.Appt_Now_Lead_Time_Minutes, referenced by Appt_ConstantValues.NOW_LEAD_MINUTES
    //      It is an integer value for the minutes between the execution of the Batch process.
    // The Notification types is a Custom Metadata value in Appt_Appointment_Setting__mdt.Appt_Now_Notification_Types, referenced by Appt_ConstantValues.NOW_NOTIFICATION_TYPES
    //      It is a string of types which can be update to provide more notifications types.  (i.e.  it is currently SMS, (SMS, EMAIL) could be added if you wanted NOW Notifications to be sent by email)
    final static string LPREFIX = 'LOG Appt_AppointmentNowBatch: ';

    //---Setup the schedule for the process
    public static void setupSchedule()
    {

        System.debug( LPREFIX + 'Setting up Appointment Now Jobs - START');

        String cronExp = Appt_SettingUtil.getSettingValue( Appt_ConstantValues.NOW_CRON_EXP);
        System.debug( LPREFIX + 'Reading CRON Expression: ' + cronExp);

        try {
            Integer nowLeadTime = Integer.valueOf( Appt_SettingUtil.getSettingValue( Appt_ConstantValues.NOW_LEAD_MINUTES) );

            if ( Test.isRunningTest() )
            {
                cronExp = '0 <minutes> 5-21 ? * MON-SAT *';
                nowLeadTime = 15;
            }

            if (cronExp == null || cronExp == '' || nowLeadTime <= 0)
            {
                System.debug( LPREFIX + 'No valid CRON Expression values, no schedules started');
            }
            else 
            {
                if ( math.mod( 60, nowLeadTime ) > 0 ) 
                {
                    System.debug( LPREFIX + 'Lead time is not a valid value, it must be evenly distributed over 60 minutes.  No schedules started.');
                }
                else 
                {
                    for (Integer cronMinutes = 0; cronMinutes < 60; cronMinutes += nowLeadTime)
                    {
                        String cronStr = cronExp.replace( '<minutes>', cronMinutes.format() );

                        System.debug( LPREFIX + 'Setting schedule to:'  + cronMinutes + ' at: ' + cronStr );

                        System.schedule('Appt_AppointmentNowScheduler ' + cronMinutes + ' at: ' + cronStr, cronStr, new Appt_AppointmentNowScheduler());
                    }
                }
            }
        } catch (TypeException e) {
            System.debug( LPREFIX + 'Lead time is not a valid value: ' + e.getMessage());
        } catch (Exception e) {
            System.debug( LPREFIX + 'Exception: ' + e.getMessage());
        }

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    }


    public void execute(SchedulableContext sc) {

        System.debug( LPREFIX + 'Start Appt_AppointmentNowScheduler execute');

        Id batchId = Database.executeBatch(new Appt_AppointmentNowBatch() );
        System.debug( 'batchId: ' + batchId );

    }

}