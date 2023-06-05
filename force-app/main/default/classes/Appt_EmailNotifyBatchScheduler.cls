public with sharing class Appt_EmailNotifyBatchScheduler  implements Schedulable {

    final static string LPREFIX = 'Appt_EmailNotifyBatchScheduler: ';

    public Appt_EmailNotifyBatchScheduler() {
        System.debug(LPREFIX + ' Constructor');
    }

    public static void setupSchedule()
    {
        System.debug( LPREFIX + 'Setting up Scheduled Jobs - START');

        String scheduleName = 'Appt_EmailBatch:';

        // give unique name so it won't fail if the real one is running
        if(Test.isRunningTest()){scheduleName = 'Appt_EmailNotifyBatchTest:';}

        // schedule hourly
        System.schedule(scheduleName+' at 00 min','0 0 * * * ?', new Appt_EmailNotifyBatchScheduler());

        System.debug( LPREFIX + 'Setting up Scheduled Jobs - END');
    }
    
    public void execute(SchedulableContext ctx)
    {
        System.debug('--- Start ' + LPREFIX + ' execute ---');
        
        Id batchId = Database.executeBatch(new Appt_EmailNotifyBatch(), 95 );
        System.debug( 'batchId: ' + batchId );

        System.debug('--- End ' + LPREFIX + ' execute ---');
    }
}