/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This setup Schedule uses the Custom Metadata values for the CRON expression and gen number of stores.  If the CRON express is empty an error log is created and the processing is terminated.  The execution method is standard, it runs the Bath process with a job size of "Slot Gen Number of Store Per Batch" (currently 3).
 */
public without sharing class Appt_GenerateApptTimeSlotsBatchScheduler implements Schedulable 
{
    public static final String LPREFIX = 'Appt_GenerateApptTimeSlotsBatchScheduler: ';

    public void execute(SchedulableContext sc) 
    {
        System.debug(' >>>>>>> Service Appointment Generate Cleanup Appt Time Slots Batch Scheduler execute ');
     
        Integer numberOfStores = Integer.valueOf(Appt_SettingUtil.getSettingValue(Appt_ConstantValues.APPOINTMENT_SETTING_SLOT_GENERATOR_NUMBER_OF_STORES_PER_BATCH));     

        if ( Test.isRunningTest() )
        {
            numberOfStores = 3;
        }

        Id batchId = Database.executeBatch(new Appt_GenerateCleanupApptTimeSlotsBatch(), numberOfStores);
        System.debug( 'batchId: ' + batchId );

    }

    //-- Apex Code to run process in Devloper Console Anonymous Execute window
    //   Appt_GenerateApptTimeSlotsBatchScheduler.setupSchedule();

    public static void setupSchedule()
    {
        System.debug( LPREFIX + 'Setting up Scheduled Jobs - START');

        String cronExp = Appt_SettingUtil.getSettingValue( Appt_ConstantValues.APPOINTMENT_SETTING_SLOT_GENERATOR_CRONEXP );
        System.debug( LPREFIX + 'Reading CRON Expression: ' + cronExp);
        
        String scheduleName = 'Appt_GenerateApptTimeSlotsBatchScheduler:';

        // deterministic Test conditions
        if ( Test.isRunningTest() )
        {
            cronExp = '0 0 0,12 * * ?';
        // give unique name so it won't fail if the real one is running
            scheduleName = 'Appt_GenerateApptTimeSlotsBatchSchedulerTest:';
        }

        if ( String.isBlank( cronExp ) )
        {
            System.debug( LPREFIX + 'No valid CRON Expression values, no schedules started');
        }
        else 
        {
            System.schedule(scheduleName + ' at: ' + cronExp, cronExp, new Appt_GenerateApptTimeSlotsBatchScheduler());

            System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
        }
    }

}