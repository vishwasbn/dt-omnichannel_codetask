/**
 * @author: Craig Petersen (craig.petersen@appsassociates.com)
 * @date: 6/14/22
 * @description:   This Batch queries all the ServiceAppointments that have the formula field Appt_Pending_Expired__c set to true.  (Appt_Pending_Expired__c is the work order created date has exceeded the Hold Cancel Time offset and the status is pending)  The Batch loops through modifying the Status value, first to null then to "Canceled Hold".  This sequence is followed to work around the state restrictions on Service Appointment Status.
 */
public class Appt_AppointmentCanceledHoldBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents
{

    final static string LPREFIX = 'Appt_AppointmentCanceledHoldBatch: ';
    public final String QUERY;
    public Appt_AppointmentCanceledHoldBatch()
    {
        System.debug('Start Appt_AppointmentCanceledHoldBatch default Constructor');
        QUERY = 'SELECT Id, Status FROM ServiceAppointment WHERE Appt_Pending_Expired__c = true';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start Appt_AppointmentCanceledHoldBatch start');
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope){

        System.debug('Start Appt_AppointmentCanceledHoldBatch execute: ' + scope.size());
        for (ServiceAppointment servAppt: scope)
        {
            servAppt.Status = null;
        }
        update scope;
        for (ServiceAppointment servAppt: scope)
        {
            servAppt.Status = Appt_ConstantValues.SERVICE_APPOINTMENT_STATUS_CANCELED_HOLD;
        }
        update scope;

        // LIMIT statistics gathering
        System.debug( LPREFIX + ' Limits:' );
        String jstr = JSON.serialize( Job_Util.getLimitListSnapshot() );
        List<String> jlist = jstr.Split('},');
        for (String obj: jList){
            System.debug('Limits: ' + obj);
        }

        System.debug('End Appt_AppointmentCanceledHoldBatch execute');
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