/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have the formula field Appointment_Missed__c set to true.  (Appointment_Missed__c is the appointment Scheduled Start time has exceeded the Missed Time Minutes offset and the status is scheduled or confirmed)  The Batch loops through modifying the Status value, first to null then to "Missed".  This sequence is followed to work around the state restrictions on Service Appointment Status.
 */
public class Appt_AppointmentMissedBatch  implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents
{
    final static string LPREFIX = 'Appt_AppointmentMissedBatch: ';
    public final String QUERY;
    public Appt_AppointmentMissedBatch()
    {
        System.debug('Start Appt_AppointmentMissedBatch default Constructor');
        QUERY = 'SELECT Id, Status FROM ServiceAppointment WHERE Appointment_Missed__c = true';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start Appt_AppointmentMissedBatch start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope){

        System.debug('Start Appt_AppointmentMissedBatch execute: ' + scope.size());
        for (ServiceAppointment servAppt: scope)
        {
            servAppt.Status = null;
        }
        update scope;
        for (ServiceAppointment servAppt: scope)
        {
            servAppt.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_MISSED;
        }
        update scope;

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('End Appt_AppointmentMissedBatch execute');
    }

    public void finish(Database.BatchableContext context)
    {
        Id batchId = context.getJobId();
        System.debug( LPREFIX + '::finish: batchId: ' + batchId);

        //---Checking final status of the Job
        AsyncApexJob apexJob = [SELECT Id, Status, ApexClassID, JobItemsProcessed, TotalJobItems, JobType, CompletedDate, ExtendedStatus FROM AsyncApexJob WHERE Id = :batchId];
        System.debug( LPREFIX + 'apexJob: ' + apexJob);
    }
}