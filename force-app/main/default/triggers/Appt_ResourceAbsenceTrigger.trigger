trigger Appt_ResourceAbsenceTrigger on ResourceAbsence (after insert, after update, after delete) 
{
    System.debug( 'Appt_ResourceAbsenceTrigger - GO');
    Appt_ResourceAbsenceTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}