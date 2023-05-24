public class Appt_AppointmentCanceledHoldScheduler  implements Schedulable {

    public void execute(SchedulableContext sc) {

        System.debug(' >>>>>>> Service Appointment Canceled Hold Scheduler execute ');
        // default call is 200 records, max is 2000 records ... executeBatch(apptCanceledHold, 2000)

        Id batchId = Database.executeBatch(new Appt_AppointmentCanceledHoldBatch(), 200);
        System.debug( 'batchId: ' + batchId );

    }
  
}