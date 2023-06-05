/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   The Batch Schedule sets up and executes the three phases (Find, Process, & Delete) for Big Object archive of Servcie Appointments.  The schedule setup creates a system schedule entry for the three phases with a numeric designation 1,2,3 differentiating the Find, Process, and Delete batches.  The execute uses the associated integer to execute the appropriate batch.
 */
public without sharing class Appt_AppointmentArchiveBatchSchedule implements Schedulable {
    
    final static string LPREFIX = 'LOG Appt_AppointmentArchiveBatchSchedule: ';

    // logging
    public Integer selectedBatchProcess = null;

    // labels
    public final static Integer BATCH_PROCESS_FIND_ARCHIVE_APPOINTMENTS = 1;
    public final static Integer BATCH_PROCESS_ARCHIVE_APPOINTMENTS = 2;
    public final static Integer BATCH_PROCESS_DELETE_APPOINTMENTS = 3;


    //---Setup the schedule for the process
    public static void setupSchedule()
    {

        System.debug( LPREFIX + 'Setting up Archive Scheduled Jobs - START');

        String cronExpList = Appt_SettingUtil.getSettingValue( Appt_ConstantValues.ARCHIVE_CRON_EXP);
        String scheduleName = 'Appt_AppointmentArchiveBatchSchedule';
        System.debug( LPREFIX + 'Reading cronExp: ' + cronExpList);

        if ( Test.isRunningTest() )
        {
            cronExpList = '0, 1 * * * ?;0, 16 * * * ?';
            scheduleName = 'Appt_AppointmentArchiveBatchTest';
        }

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
                        System.debug( LPREFIX + 'Setting schedule to:'  + cronExp);

                        System.schedule( scheduleName + ' 1 at: ' + cronExp, cronExp, new Appt_AppointmentArchiveBatchSchedule(BATCH_PROCESS_FIND_ARCHIVE_APPOINTMENTS));
                    }
                }
            }
        }

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    } // End of setupSchedule()

    public Appt_AppointmentArchiveBatchSchedule(Integer batchProcess) 
    {
        selectedBatchProcess = batchProcess;
    }

    //---Process to execute the Scheduled job
    public void execute(SchedulableContext ctx)
    {
        System.debug('--- Start Appt_AppointmentArchiveBatchSchedule execute ---');
        Id batchId;
        
        if (selectedBatchProcess == null) 
        {
            System.debug('Archive scheduled batch process not defined');
        } 
        else if (selectedBatchProcess == BATCH_PROCESS_FIND_ARCHIVE_APPOINTMENTS) 
        {
            // findAppointmentsToArchive();
            batchId = Database.executeBatch(new Appt_AppointmentArchiveFindBatch() );
            System.debug('batchId' + batchId);
        } 
        else
        {
            System.debug('Invalid batchProcess value: ' + String.valueOf(selectedBatchProcess));
        }
        System.debug('--- End Appt_AppointmentArchiveBatchSchedule execute ---');

    }

}