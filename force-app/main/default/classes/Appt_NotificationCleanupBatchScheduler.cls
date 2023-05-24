/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:    This Batch is subtly different, it supports a CRON expression with the option of including multiple expressions separated by a semi colon.  The CRON expression(s) is/are turned into Batch Schedules.  The execution method is standard, it runs the Bath process.
 */
public class Appt_NotificationCleanupBatchScheduler implements Schedulable 
{
    final static string LPREFIX = 'APPT_NOTIFICATION_CLEANUP_SCHEDULABLE: ';
    public static void setupSchedule()
    {

        System.debug( LPREFIX + 'Setting up Archive Scheduled Jobs - START');

        List<Appt_Appointment_Setting__mdt> notificationPurgeCronSetting = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Notification_Purge_Batch_Schedule_Cron'];       

        String cronExpList = notificationPurgeCronSetting[0].Value__c;
        System.debug( LPREFIX + 'Reading cronExp: ' + cronExpList);

        if (cronExpList == null || cronExpList == '')
        {
            System.debug( LPREFIX + 'No valid CronExp values, no schedules started');
        }
        else 
        {
            String[] cronStringList = cronExpList.split(';');

            if (cronStringList == null || cronStringList.size() == 0 )
            {
                System.debug( LPREFIX + 'No valid CronExp values, no schedules started');
            }
            else 
            {

                for (String cronExp : cronStringList)
                {
                    System.debug( LPREFIX + 'Found cronExpr: ' + cronExp);

                    if (cronExp != null && cronExp != '') 
                    {           
                        String scheduleName = 'NotificationCleanupBatchSchedule at: '; 

                        // give a unique name for test runs so it doesn't conflict with a real batch schedule 
                        if(Test.isRunningTest()){
                            scheduleName = 'NotificationCleanupBatchScheduleTest at: ';
                        }            
                        System.debug( LPREFIX + 'Setting schedule to:'  + cronExp);
                        System.schedule(scheduleName + cronExp, cronExp, new Appt_NotificationCleanupBatchScheduler());
                    }
                }
            }
        }

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    }    

    public void execute(SchedulableContext sc) {        
        System.debug( LPREFIX + ' Execute schedule');
        Id batchId = Database.executeBatch(new Appt_NotificationCleanupBatch());
        System.debug( 'batchId: ' + batchId );

    }
}