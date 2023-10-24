/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have an archive status of null and a scheduled start time of less than the custom metadata 'Archive_Number_of_Days' (currently 365) adjusted current date. (i.e. appointments over a year old).  The Batch updates the records Archive Status to 'Processing'. 
 */
public class Appt_AppointmentArchiveFindBatch  implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents
{
    final static string LPREFIX = 'LOG Appt_AppointmentArchiveFindBatch: ';
    public final String QUERY;

    public Appt_AppointmentArchiveFindBatch() 
    {
        List<Appt_Appointment_Setting__mdt> settings = Appt_SettingUtil.getApptSettings();
        Integer daysToArchive = Integer.valueOf(Appt_SettingUtil.getSettingValue( Appt_ConstantValues.ARCHIVE_NUMBER_OF_DAYS, settings));
        Datetime archiveDate = System.today().addDays( ( daysToArchive * -1 ) );
        //APP3-302 : Changed the filter from SchedStartTime to "DueDate" field in Where clause as SchedStartTime field value is  blank in some cases.
        QUERY = 'SELECT Id from ServiceAppointment WHERE Date_String__c != null AND DueDate < ' + archiveDate.format('yyyy-MM-dd\'T\'HH:mm:\'00Z\'','UTC') + ' AND Archive_Status__c = null ORDER BY Date_String__c ASC';
        System.debug('QUERY: ' + QUERY);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug( LPREFIX + 'start');
        System.debug( LPREFIX + 'QUERY: ' + QUERY);
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Object> scope)
    {
        System.debug( LPREFIX + 'start execute');
        System.debug( LPREFIX + 'serviceAppointments to start processing: ' + scope.size());

        Integer processedCount = 0;
        List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
            
        for (ServiceAppointment sa : (List<ServiceAppointment>)scope) 
        {
            ServiceAppointment saToUpdate = new ServiceAppointment(Id = sa.Id, Archive_Status__c = Appt_ConstantValues.ARCHIVE_STATUS_PROCESSING);
            saToUpdateList.add(saToUpdate);
            processedCount++;
        }

        // update service appointments to "Processing" Archive status
        if (saToUpdateList.size() > 0) 
        {
            update saToUpdateList;
        }

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug(LPREFIX + ' ' + String.valueOf(processedCount) + ' records set to Archive Status "Processing".');
        System.debug( LPREFIX + 'stop execute');
    }

    public void finish(Database.BatchableContext context)
    {
        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);

        // Adding call to processBatch to synchronize the archiving process
        Database.executeBatch(new Appt_AppointmentArchiveProcessBatch());
    }

}