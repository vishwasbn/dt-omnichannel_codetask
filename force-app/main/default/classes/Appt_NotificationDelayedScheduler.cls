/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:    This Batch is subtly different, it supports a CRON expression with the option of including multiple expressions separated by a semi colon.  The CRON expression(s) is/are turned into Batch Schedules.  The execution method is standard, it runs the Bath process.
 */
public with sharing class Appt_NotificationDelayedScheduler implements Schedulable {

    final static string LPREFIX = 'Appt_NotificationDelayedScheduler: ';
    public static void setupSchedule()
    {

        System.debug( LPREFIX + 'Setting up Archive Scheduled Jobs - START');

        List<Appt_Appointment_Setting__mdt> notificationDelayedSendCronSetting = [SELECT Id, DeveloperName, Value__c FROM Appt_Appointment_Setting__mdt WHERE DeveloperName = 'Notification_Delayed_Send_Batch_Cron'];       

        String cronExpList = notificationDelayedSendCronSetting[0].Value__c;
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
                        String scheduleName = 'Appt_NotificationDelayedSendBatchSchedule at: '; 

                        // give a unique name for test runs so it doesn't conflict with a real batch schedule 
                        if(Test.isRunningTest()){
                            scheduleName = 'Appt_NotificationDelayedSendBatchTest at: ';
                        }            
                        System.debug( LPREFIX + 'Setting schedule to:'  + cronExp);
                        System.schedule(scheduleName + cronExp, cronExp, new Appt_NotificationDelayedScheduler());
                    }
                }
            }
        }

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    }   
    
    public static void process(){
        System.debug( LPREFIX + ' Execute schedule');
        Integer batchSize = Integer.valueOf( Appt_SettingUtil.getSettingValue( 'Notification_Delayed_Send_Batch_Size') );
        System.debug('batchSize: ' + batchSize);

        Id batchId = Database.executeBatch(new Appt_NotificationDelayedSendBatch(), batchSize);
        System.debug( 'batchId: ' + batchId );
    }

    public void execute(SchedulableContext sc) {        
        process();
    }
}