trigger Appt_ServiceAppointmentTrigger on ServiceAppointment (after insert, before update, after update, before delete) {
    System.debug( 'Appt_ServiceAppointmentTrigger - GO');
    Appt_ServiceAppointmentTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}