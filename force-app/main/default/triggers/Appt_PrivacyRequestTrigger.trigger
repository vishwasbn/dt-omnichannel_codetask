trigger Appt_PrivacyRequestTrigger on Privacy_Request__c (after insert, before update, after update) {
    System.debug( 'Appt_PrivacyRequestTrigger - GO');
    Appt_PrivacyRequestTriggerHandler.handle(Trigger.oldMap, Trigger.newMap, Trigger.operationType);
}