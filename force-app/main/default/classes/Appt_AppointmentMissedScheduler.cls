public class Appt_AppointmentMissedScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {

        System.debug(' >>>>>>> Service Appointment Missed Scheduler execute ');
        // default call is 200 records, max is 2000 records ... executeBatch(apptCanceledHold, 2000)

        Id batchId = Database.executeBatch(new Appt_AppointmentMissedBatch(), 200);
        System.debug('batchId: ' + batchId);

    }
}